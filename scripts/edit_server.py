#!/usr/bin/env python3
"""本地编辑服务：根据网页 URL 找到对应的 Markdown 文件并用 Typora 打开。

只监听 127.0.0.1，供本机浏览器里的“本地编辑”按钮调用。
"""
import json
import os
import re
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT = os.path.join(ROOT, "content")
HOST = "127.0.0.1"
PORT = int(os.environ.get("BLOG_EDIT_PORT", "8787"))
DRY = os.environ.get("BLOG_EDIT_DRY") == "1"


def safe(path):
    path = os.path.realpath(path)
    return path.startswith(os.path.realpath(CONTENT) + os.sep)


def read_url_field(md):
    try:
        with open(md, encoding="utf-8", errors="ignore") as fh:
            head = fh.read(2000)
    except OSError:
        return None
    m = re.search(r'^url:\s*"?([^"\n]+)"?', head, re.M)
    return m.group(1).strip() if m else None


def build_map():
    """URL -> markdown 文件"""
    mapping = {}
    for base, _, files in os.walk(CONTENT):
        for name in files:
            if not name.endswith(".md") or name == "_index.md":
                continue
            md = os.path.join(base, name)
            u = read_url_field(md)
            if u:
                mapping[u.rstrip("/") + "/"] = md
    return mapping


def find_for_path(path):
    path = "/" + path.strip("/") + "/"
    mapping = build_map()
    if path in mapping:
        return mapping[path]

    parts = [p for p in path.strip("/").split("/") if p]
    if not parts:
        return None

    # /posts/<type>/<...> 或 /star/<belong>/<...>
    if parts[0] in ("posts", "star"):
        rel = parts[1:]
        folder = os.path.join(CONTENT, parts[0], *rel)
        if not safe(folder) or not os.path.isdir(folder):
            return None
        if parts[0] == "star":
            info = os.path.join(folder, "Info.md")
            return info if os.path.isfile(info) else None
        md_files = [
            f for f in sorted(os.listdir(folder))
            if f.endswith(".md") and f not in ("_index.md", "Info.md")
        ]
        if not md_files:
            info = os.path.join(folder, "Info.md")
            return info if os.path.isfile(info) else None
        target = os.path.basename(folder.rstrip("/")) + ".md"
        if target in md_files:
            return os.path.join(folder, target)
        return os.path.join(folder, md_files[0])
    return None


def open_file(path):
    if DRY:
        return True, path
    opener = os.environ.get("BLOG_EDITOR")
    if not opener:
        for cand in ("typora", "xdg-open"):
            from shutil import which
            if which(cand):
                opener = cand
                break
    if not opener:
        return False, "找不到 Typora，也没有设置 BLOG_EDITOR"
    subprocess.Popen(
        [opener, path],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    return True, path


class Handler(BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")

    def _json(self, code, obj):
        body = json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(code)
        self._cors()
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        u = urlparse(self.path)
        if u.path == "/status":
            self._json(200, {"ok": True, "root": ROOT})
            return
        if u.path == "/edit":
            target = parse_qs(u.query).get("url", [""])[0]
            if not target:
                self._json(400, {"ok": False, "error": "缺少 url 参数"})
                return
            md = find_for_path(target)
            if not md or not safe(md):
                self._json(404, {"ok": False, "error": "没有找到对应的文件"})
                return
            ok, msg = open_file(md)
            rel = os.path.relpath(md, ROOT)
            self._json(200 if ok else 500, {"ok": ok, "file": rel, "error": None if ok else msg})
            return
        self._json(404, {"ok": False, "error": "not found"})

    def log_message(self, fmt, *args):
        sys.stderr.write("[blog-edit] " + (fmt % args) + "\n")


if __name__ == "__main__":
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"本地编辑服务已启动: http://{HOST}:{PORT}")
    print("保持这个窗口打开，网页上的“本地编辑”按钮才可用。Ctrl+C 结束。")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
