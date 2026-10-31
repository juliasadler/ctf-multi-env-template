#!/usr/bin/env python3
"""tmuxshot：把 tmux 会话里的命令执行过程（含输出、颜色）渲染成文档用截图。

用法：
  # 直接对本机 tmux 会话截图（默认只截当前可见窗格）
  python3 tmuxshot.py --target my-session -o shot.png

  # 带上回滚历史（最近 200 行）
  python3 tmuxshot.py --target my-session --scrollback 200 -o shot.png

  # 不经过 tmux：把已有的 capture-pane 文本（-e 保留颜色）转成图
  tmux capture-pane -t my-session -p -e > pane.txt
  python3 tmuxshot.py --input pane.txt -o shot.png

  # 从管道读
  tmux capture-pane -t my-session -p -e | python3 tmuxshot.py -o shot.png

原理（对应 Full-Chain-Sentinel-System MITM_Fuzz_Render 的 CDP 管线）：
  tmux capture-pane -e 取带 ANSI 颜色的文本
    → ansi2html 转成带内联样式的 HTML 片段
    → 包一层终端窗口框（标题栏 + 深色底 + 等宽字体）
    → 用 chrome-headless-shell + CDP 截图（Page.captureScreenshot）
  不依赖 Playwright / Puppeteer，只用一条 WebSocket + CDP 命令。

环境要求：tmux（只在 --target 模式需要）、chrome-headless-shell
  （默认用 Playwright 缓存里的那份；也可用 --chrome 指定路径，
  或设环境变量 TMUXSHOT_CHROME）。
"""
import argparse, asyncio, base64, json, os, re, subprocess, sys, tempfile, time

DEFAULT_CHROME = os.path.expanduser(
    "~/.cache/ms-playwright/chromium_headless_shell-1248/"
    "chrome-headless-shell-linux64/chrome-headless-shell")


def get_chrome(explicit):
    for cand in (explicit, os.environ.get("TMUXSHOT_CHROME"), DEFAULT_CHROME):
        if cand and os.path.isfile(cand) and os.access(cand, os.X_OK):
            return cand
    raise SystemExit("找不到 chrome-headless-shell：请用 --chrome 指定，或设 TMUXSHOT_CHROME")


def capture_tmux(target, scrollback):
    cmd = ["tmux", "capture-pane", "-t", target, "-p", "-e", "-J"]
    if scrollback is not None:
        cmd += ["-S", f"-{scrollback}"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit(f"tmux capture-pane 失败：{r.stderr.strip()}\n"
                         "请确认会话名（tmux ls 查看）或改用 --input 传入已抓好的文本")
    return r.stdout


def clean_ansi(text):
    # 每行去尾部空白、去掉末尾空行；保留行首缩进与颜色转义
    lines = [ln.rstrip() for ln in text.split("\n")]
    while lines and not lines[-1].strip():
        lines.pop()
    return "\n".join(lines)


def ansi_to_html(text):
    from ansi2html import Ansi2HTMLConverter
    conv = Ansi2HTMLConverter(dark_bg=True, inline=True)
    return conv.convert(text, full=False)


def build_page(body_html, title, font_size, pad):
    return f"""<!DOCTYPE html><html><head><meta charset="utf-8">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{ background: #ffffff; }}
  .term {{
    display: inline-block; min-width: 200px;
    background: #1e1e2e; border-radius: 10px;
    box-shadow: 0 8px 30px rgba(0,0,0,.25);
    overflow: hidden; font-family: "DejaVu Sans Mono", "Noto Sans Mono",
      "Noto Sans CJK SC", monospace;
    font-size: {font_size}px; line-height: 1.55;
  }}
  .bar {{
    display: flex; align-items: center; gap: 7px;
    background: #2b2b3d; padding: 9px 13px;
    color: #c9c9d6; font-size: {max(font_size - 2, 11)}px;
  }}
  .dot {{ width: 12px; height: 12px; border-radius: 50%; }}
  .red {{ background: #ff5f57; }} .yellow {{ background: #febc2e; }} .green {{ background: #28c840; }}
  .title {{ margin-left: 8px; white-space: nowrap; }}
  .body {{ padding: {pad}px {pad + 4}px; color: #e6e6e6; white-space: pre; }}
  .body span {{ white-space: pre; }}
</style></head><body>
<div class="term" id="term"><div class="bar"><span class="dot red"></span><span class="dot yellow"></span><span class="dot green"></span><span class="title">{title}</span></div><div class="body" id="tbody">{body_html}</div></div>
</body></html>"""


class CDP:
    def __init__(self, ws):
        self.ws, self.n = ws, 0

    async def call(self, method, params=None, session=None):
        self.n += 1
        mid = self.n
        msg = {"id": mid, "method": method}
        if params is not None:
            msg["params"] = params
        if session:
            msg["sessionId"] = session
        await self.ws.send(json.dumps(msg))
        while True:
            d = json.loads(await self.ws.recv())
            if d.get("id") == mid:
                if "error" in d:
                    raise RuntimeError(f"{method}: {d['error']}")
                return d.get("result", {})

    async def evaluate(self, session, expr):
        r = await self.call("Runtime.evaluate",
                            {"expression": expr, "returnByValue": True}, session)
        return r["result"]["value"]


async def screenshot(html_path, out_path, chrome, scale):
    import websockets
    profile = tempfile.mkdtemp(prefix="tmuxshot-profile-")
    proc = subprocess.Popen(
        [chrome, "--headless=new", "--remote-debugging-port=0",
         "--user-data-dir=" + profile, "--no-first-run",
         "--no-default-browser-check", "--disable-background-networking",
         "--disable-extensions", "--disable-sync", "--disable-translate",
         "--disable-component-update", "--mute-audio", "--hide-scrollbars",
         "--window-size=1920,12000", "--disable-dev-shm-usage", "--no-sandbox",
         "--force-device-scale-factor=1"],
        stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
    ws_url, t0 = None, time.time()
    for line in proc.stderr:
        m = re.search(r"DevTools listening on (ws://\S+)", line)
        if m:
            ws_url = m.group(1)
            break
        if time.time() - t0 > 30:
            proc.kill()
            raise RuntimeError("30s 内未拿到 DevTools 端点")
    try:
        async with websockets.connect(ws_url, max_size=128 * 1024 * 1024) as ws:
            c = CDP(ws)
            ctx = await c.call("Target.createBrowserContext")
            tgt = await c.call("Target.createTarget",
                               {"url": "about:blank",
                                "browserContextId": ctx["browserContextId"]})
            att = await c.call("Target.attachToTarget",
                               {"targetId": tgt["targetId"], "flatten": True})
            s = att["sessionId"]
            await c.call("Page.enable", session=s)
            await c.call("Runtime.enable", session=s)
            await c.call("Emulation.setDeviceMetricsOverride",
                         {"width": 1920, "height": 12000,
                          "deviceScaleFactor": scale, "mobile": False}, s)
            nav = await c.call("Page.navigate",
                               {"url": "file://" + html_path}, s)
            assert not nav.get("errorText"), nav
            while True:
                if await c.evaluate(s, "document.readyState") == "complete":
                    break
                await asyncio.sleep(0.1)
            # 量出终端框的实际尺寸，再把视口精确收成框的大小后截图
            size = await c.evaluate(
                s, "(() => { const el = document.getElementById('term');"
                   " return {w: Math.ceil(el.scrollWidth), "
                   "h: Math.ceil(el.scrollHeight)}; })()")
            await c.call("Emulation.setDeviceMetricsOverride",
                         {"width": size["w"], "height": size["h"],
                          "deviceScaleFactor": scale, "mobile": False}, s)
            shot = await c.call("Page.captureScreenshot",
                                {"format": "png", "fromSurface": True}, s)
            with open(out_path, "wb") as f:
                f.write(base64.b64decode(shot["data"]))
            return size["w"], size["h"]
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()


def main():
    ap = argparse.ArgumentParser(description="tmux 会话 → 终端截图（文档用）")
    ap.add_argument("--target", help="tmux 目标，如 my-session / session:window.pane")
    ap.add_argument("--input", help="已抓好的 capture-pane 文本文件（-e 保留颜色）；不填则读 stdin")
    ap.add_argument("--scrollback", type=int, default=None, help="回滚行数，如 200（默认只截可见窗格）")
    ap.add_argument("--title", default="tmux", help="标题栏文字，默认 tmux")
    ap.add_argument("--font-size", type=int, default=15)
    ap.add_argument("--scale", type=float, default=2.0, help="截图倍率，默认 2（文档里更清晰）")
    ap.add_argument("--chrome", default=None)
    ap.add_argument("-o", "--output", required=True)
    args = ap.parse_args()

    if args.target:
        text = capture_tmux(args.target, args.scrollback)
    elif args.input:
        text = open(args.input, encoding="utf-8", errors="replace").read()
    else:
        text = sys.stdin.read()
    text = clean_ansi(text)
    if not text.strip():
        raise SystemExit("抓到的内容是空的：请确认目标会话里确实有输出")

    html = build_page(ansi_to_html(text), args.title, args.font_size, 16)
    tmpdir = tempfile.mkdtemp(prefix="tmuxshot-")
    html_path = os.path.join(tmpdir, "term.html")
    open(html_path, "w", encoding="utf-8").write(html)
    w, h = asyncio.run(screenshot(html_path, args.output,
                                  get_chrome(args.chrome), args.scale))
    print(f"已生成 {args.output}（逻辑尺寸 {w}x{h}，倍率 {args.scale}，"
          f"实际像素 {int(w * args.scale)}x{int(h * args.scale)}）")


if __name__ == "__main__":
    main()
