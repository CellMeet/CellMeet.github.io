#!/usr/bin/env python3
"""快速添加友链：link <网址>

自动抓取网站名称和图标，保存图标到 static/img/links/<名称>.png，
并把友链追加到 content/links.md。
"""
import os
import re
import subprocess
import sys
import tempfile
import time
import unicodedata
from html.parser import HTMLParser
from urllib.parse import urljoin, urlparse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LINKS_MD = os.path.join(ROOT, "content", "links.md")
ICON_DIR = os.path.join(ROOT, "static", "img", "links")
UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)
COOKIE_JAR = os.path.join(tempfile.gettempdir(), f"addlink-cookies-{os.getpid()}.txt")
BASE_CMD = ["curl", "-sL", "--max-time", "25", "-A", UA, "-c", COOKIE_JAR, "-b", COOKIE_JAR]


class HeadParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.title = ""
        self.site_name = ""
        self.app_name = ""
        self.icons = []
        self._in_title = False
        self._in_head = True

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "title":
            self._in_title = True
        elif tag == "body":
            self._in_head = False
        elif tag == "meta" and self._in_head:
            prop = (attrs.get("property") or attrs.get("name") or "").lower()
            content = (attrs.get("content") or "").strip()
            if prop == "og:site_name" and content:
                self.site_name = content
            elif prop in ("application-name", "apple-mobile-web-app-title") and content:
                self.app_name = content
        elif tag == "link" and self._in_head:
            rel = (attrs.get("rel") or "").lower()
            href = (attrs.get("href") or "").strip()
            sizes = (attrs.get("sizes") or "").strip()
            if href and "icon" in rel:
                self.icons.append((rel, href, sizes))

    def handle_endtag(self, tag):
        if tag == "title":
            self._in_title = False

    def handle_data(self, data):
        if self._in_title:
            self.title += data


def curl(url, binary=False, timeout=25):
    cmd = BASE_CMD + ["--max-time", str(timeout)]
    try:
        r = subprocess.run(cmd + [url], capture_output=True, timeout=timeout + 5)
    except subprocess.TimeoutExpired:
        return None
    if r.returncode != 0 or not r.stdout:
        return None
    return r.stdout if binary else r.stdout.decode("utf-8", "replace")


def page_and_final_url(url):
    cmd = BASE_CMD + ["--max-time", "25", "-w", "\n__META__%{url_effective} %{http_code}", url]
    html, final = None, url
    for attempt in range(2):
        try:
            r = subprocess.run(cmd, capture_output=True, timeout=30)
        except subprocess.TimeoutExpired:
            return None, url
        if r.returncode != 0 or not r.stdout:
            return None, url
        text = r.stdout.decode("utf-8", "replace")
        if "__META__" in text:
            body, meta = text.rsplit("__META__", 1)
            parts = meta.strip().rsplit(" ", 1)
            if len(parts) == 2:
                final, code = parts[0], parts[1]
            else:
                final, code = meta.strip(), ""
        else:
            body, code = text, ""
        html = body
        if code == "200" and len(body) > 500:
            return html, final
        time.sleep(1)
    return html, final


def clean_title(t):
    t = re.sub(r"\s+", " ", t or "").strip()
    for sep in (" | ", " · ", " — ", " – ", " - "):
        if sep in t:
            t = t.split(sep)[0].strip()
    return t


def slugify(name, domain):
    s = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s).strip("-").lower()
    if not s:
        s = re.sub(r"[^a-zA-Z0-9]+", "-", domain).strip("-").lower()
    return s or "site"


def detect_ext(data):
    if not data or len(data) < 16:
        return None
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    if data.startswith(b"\xff\xd8"):
        return "jpg"
    if data.startswith(b"GIF8"):
        return "gif"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "webp"
    if data.startswith(b"\x00\x00\x01\x00") or data.startswith(b"\x00\x00\x02\x00"):
        return "ico"
    head = data[:600].lstrip().lower()
    if head.startswith(b"<svg") or (head.startswith(b"<?xml") and b"<svg" in head):
        return "svg"
    return None


def save_icon(data, slug):
    ext = detect_ext(data)
    if not ext:
        return ""
    os.makedirs(ICON_DIR, exist_ok=True)
    fname = f"{slug}.{ext}"
    dest = os.path.join(ICON_DIR, fname)
    with open(dest, "wb") as f:
        f.write(data)
    return f"/img/links/{fname}"


def online_icon(domain):
    """在线接口（favicon.run 使用的同款接口）：拿不到站点图标时兜底。"""
    urls = [
        f"https://www.google.com/s2/favicons?domain={domain}&sz=128",
        f"https://favicon.run/favicon?domain={domain}",
    ]
    for u in urls:
        data = curl(u, binary=True, timeout=15)
        if data and detect_ext(data):
            return data
    return None


def choose_icon(parser, final_url):
    base = final_url
    cands = []
    for rel, href, sizes in parser.icons:
        score = 0
        if "apple-touch-icon" in rel:
            score += 5
        if "shortcut" in rel:
            score += 1
        if "icon" in rel:
            score += 3
        for m in re.findall(r"(\d+)x(\d+)", sizes):
            score += min(int(m[0]) / 64.0, 4)
        if href.startswith("data:"):
            continue
        cands.append((score, urljoin(base, href)))
    cands.append((-1, urljoin(base, "/favicon.ico")))

    seen = set()
    for _, icon_url in sorted(cands, key=lambda x: x[0], reverse=True):
        if icon_url in seen:
            continue
        seen.add(icon_url)
        yield icon_url


def yaml_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def normalize_url(u):
    p = urlparse(u)
    host = p.netloc.lower()
    path = p.path.rstrip("/")
    return f"{p.scheme}://{host}{path}"


def url_exists(url):
    if not os.path.exists(LINKS_MD):
        return False
    text = open(LINKS_MD, encoding="utf-8").read()
    target = normalize_url(url)
    for m in re.finditer(r'^\s*url:\s*["\']?([^"\'\s]+)', text, re.M):
        if normalize_url(m.group(1)) == target:
            return True
    return False


def update_avatar(url, avatar):
    if not os.path.exists(LINKS_MD):
        return False
    text = open(LINKS_MD, encoding="utf-8").read()
    target = normalize_url(url)
    lines = text.splitlines()
    in_block = False
    changed = False
    for i, line in enumerate(lines):
        m = re.match(r'^\s*url:\s*["\']?([^"\'\s]+)', line)
        if m and normalize_url(m.group(1)) == target:
            in_block = True
            # already has avatar?
            for j in range(i + 1, min(i + 4, len(lines))):
                if re.match(r'^\s*avatar:', lines[j]):
                    if avatar:
                        lines[j] = f'    avatar: "{avatar}"'
                        changed = True
                    break
            else:
                if avatar:
                    lines.insert(i + 1, f'    avatar: "{avatar}"')
                    changed = True
            break
    if changed:
        open(LINKS_MD, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    return changed


def add_to_links(name, url, avatar):
    if not os.path.exists(LINKS_MD):
        print(f"找不到 {LINKS_MD}", file=sys.stderr)
        return False
    text = open(LINKS_MD, encoding="utf-8").read()

    target = normalize_url(url)
    for m in re.finditer(r'^\s*url:\s*["\']?([^"\'\s]+)', text, re.M):
        if normalize_url(m.group(1)) == target:
            print(f"友链已存在: {m.group(1)}")
            return False

    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        print("links.md 格式不对（缺少 front matter）", file=sys.stderr)
        return False
    end = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end = i
            break
    if end is None:
        print("links.md 格式不对（缺少结尾 ---）", file=sys.stderr)
        return False

    front = lines[1:end]
    has_links = any(l.strip() == "links:" for l in front)
    entry = [
        f'  - name: "{yaml_escape(name)}"',
        f'    url: "{yaml_escape(url)}"',
        f'    avatar: "{yaml_escape(avatar)}"',
        '    description: ""',
    ]

    insert_at = end
    if not has_links:
        front.append("links:")
        insert_at = end

    new_lines = lines[:insert_at]
    if not has_links:
        new_lines.append("links:")
    new_lines.extend(entry)
    new_lines.extend(lines[insert_at:])

    open(LINKS_MD, "w", encoding="utf-8").write("\n".join(new_lines) + "\n")
    return True


def main():
    args = sys.argv[1:]
    update_only = False
    if "--update" in args:
        update_only = True
        args = [a for a in args if a != "--update"]
    if not args:
        try:
            url = input("网址: ").strip()
        except EOFError:
            return 1
    else:
        url = args[0].strip()

    if not url:
        print("网址不能为空", file=sys.stderr)
        return 1
    if not re.match(r"^https?://", url, re.I):
        url = "https://" + url
    url = url.strip()

    if url_exists(url) and not update_only:
        print(f"友链已存在: {url}（如需更新图标，加 --update）")
        return 0

    print(f"抓取: {url}")
    html, final_url = page_and_final_url(url)
    if not html:
        print("抓取失败，请检查网址或网络", file=sys.stderr)
        return 1

    parser = HeadParser()
    try:
        parser.feed(html)
    except Exception:
        pass

    domain = urlparse(final_url).netloc.replace("www.", "")
    name = parser.site_name or parser.app_name or clean_title(parser.title) or domain
    name = name[:60].strip()
    slug = slugify(name, domain)

    os.makedirs(ICON_DIR, exist_ok=True)
    icon_rel = ""
    used = ""

    # 优先使用网站自己的图标，保留原始格式（png/jpg/webp/svg/ico 都行）
    for icon_url in choose_icon(parser, final_url):
        data = curl(icon_url, binary=True, timeout=20)
        rel = save_icon(data, slug) if data else ""
        if rel:
            icon_rel = rel
            used = icon_url
            break

    # 找不到时用在线接口兜底
    if not icon_rel:
        data = online_icon(domain)
        if data:
            icon_rel = save_icon(data, slug)
            used = "online favicon api"

    if not icon_rel:
        print("没有找到可用图标，先不设置头像")
    else:
        print(f"图标: {used}")
        print(f"已保存: {icon_rel.lstrip('/')}")

    if update_only:
        if update_avatar(url, icon_rel):
            print(f"已更新图标: {url} → {icon_rel}")
            print("运行 publish 发布")
        else:
            print("没有更新（可能网址不存在或图标为空）")
        return 0

    if add_to_links(name, url, icon_rel):
        print(f"已添加友链: {name} → {url}")
        print("运行 publish 发布")
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
