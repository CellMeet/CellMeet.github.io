#!/usr/bin/env python3
"""交互式新建内容向导。

一个步骤里同时出现 title 和 category：
- title 必须用双引号包裹
- 标题确认后光标直接移到下面的 category，候选在输入后才出现
- book/movie 时再输入书名/电影名，书名不需要引号也能匹配
- Esc 可返回上一步修改，Ctrl-C 取消

结果以 TITLE\\x1f..., CATEGORY\\x1f..., NAME\\x1f... 输出到标准输出。
"""
import locale
import os
import select
import shutil
import sys
import termios
import tty
import unicodedata

for _loc in ("C.UTF-8", "en_US.UTF-8", "zh_CN.UTF-8", ""):
    try:
        locale.setlocale(locale.LC_ALL, _loc)
        break
    except locale.Error:
        continue

BACK = object()


def dw(s):
    width = 0
    for ch in s:
        width += 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
    return width


def term_width():
    try:
        return max(20, shutil.get_terminal_size((80, 24)).columns)
    except OSError:
        return 80


def fit(s, width):
    if width <= 1 or dw(s) <= width:
        return s
    out = []
    w = 0
    for ch in s:
        cw = 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
        if w + cw > width - 1:
            break
        out.append(ch)
        w += cw
    return "".join(out) + "…"


def field_view(label, text, cursor, width):
    full = label + text
    if dw(full) <= width - 1:
        return full, dw(label + text[:cursor])
    avail = width - 2 - dw(label + "…")
    if avail < 4:
        avail = 4
    tail = []
    w = 0
    for ch in reversed(text):
        cw = 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
        if w + cw > avail:
            break
        tail.append(ch)
        w += cw
    tail = "".join(reversed(tail))
    start = len(text) - len(tail)
    shown = label + "…" + tail
    if cursor >= start:
        col = dw(label + "…" + text[start:cursor])
    else:
        col = dw(label + "…")
    return shown, min(col, width - 2)


def norm(s):
    return "".join(ch for ch in s.lower() if ch.isalnum())


def is_subseq(q, s):
    it = iter(s)
    return all(ch in it for ch in q)


def score(q, s):
    if not q:
        return 0
    ns = norm(s)
    if ns.startswith(q):
        return 0
    if q in ns:
        return 1
    if is_subseq(q, ns):
        return 2
    return 99


def fuzzy(items, q):
    nq = norm(q)
    out = [it for it in items if score(nq, it) < 99]
    out.sort(key=lambda it: (score(nq, it), len(norm(it)), it.lower()))
    return out


def unquote(s):
    t = s.strip()
    if len(t) >= 2 and t[0] == '"' and t[-1] == '"':
        return t[1:-1]
    return None


def loose_value(s):
    """书名/电影名：引号可有可无，匹配时去掉首尾引号。"""
    return s.strip().strip('"')


def read_key():
    b = os.read(0, 1)
    if not b:
        return "CTRL_C"

    if b == b"\x1b":
        seq = b""
        while len(seq) < 4 and select.select([0], [], [], 0.005)[0]:
            seq += os.read(0, 1)
        mapping = {
            b"[A": "UP",
            b"[B": "DOWN",
            b"[C": "RIGHT",
            b"[D": "LEFT",
            b"[H": "HOME",
            b"[F": "END",
            b"[1~": "HOME",
            b"[4~": "END",
            b"[3~": "DEL",
        }
        return mapping.get(seq, "ESC")

    if b in (b"\r", b"\n"):
        return "ENTER"
    if b in (b"\x7f", b"\x08"):
        return "BS"
    if b == b"\x03":
        return "CTRL_C"
    if b == b"\x15":
        return "CTRL_U"

    if b[0] < 0x80:
        ch = b.decode("ascii", "replace")
        return ch if ord(ch) >= 32 else None

    need = 1 if b[0] < 0xE0 else 2 if b[0] < 0xF0 else 3
    data = b
    for _ in range(need):
        data += os.read(0, 1)
    return data.decode("utf-8", "replace")


class Screen:
    def __init__(self):
        self.up = 0

    def write(self, s):
        sys.stdout.write(s)
        sys.stdout.flush()

    def draw(self, lines, active_idx, cursor_col):
        out = []
        if self.up:
            out.append(f"\x1b[{self.up}A")
        out.append("\r\x1b[J")
        out.append("\n".join(lines))
        below = len(lines) - 1 - active_idx
        if below > 0:
            out.append(f"\x1b[{below}A")
        out.append("\r")
        if cursor_col:
            out.append(f"\x1b[{cursor_col}C")
        self.write("".join(out))
        self.up = active_idx

    def finish(self, lines):
        out = []
        if self.up:
            out.append(f"\x1b[{self.up}A")
        out.append("\r\x1b[J")
        out.append("\n".join(lines) + "\n")
        self.write("".join(out))
        self.up = 0


def handle_edit(key, text, cursor):
    if key == "LEFT":
        return text, max(0, cursor - 1), True
    if key == "RIGHT":
        return text, min(len(text), cursor + 1), True
    if key == "HOME":
        return text, 0, True
    if key == "END":
        return text, len(text), True
    if key == "BS":
        if cursor > 0:
            return text[: cursor - 1] + text[cursor:], cursor - 1, True
        return text, cursor, True
    if key == "DEL":
        if cursor < len(text):
            return text[:cursor] + text[cursor + 1:], cursor, True
        return text, cursor, True
    if key == "CTRL_U":
        return "", 0, True
    if len(key) >= 1 and key.isprintable():
        return text[:cursor] + key + text[cursor:], cursor + len(key), True
    return text, cursor, False


def edit_title_category(screen, categories):
    title = ""
    tcur = 0
    cat = ""
    ccur = 0
    active = "title"
    sel = 0
    error = ""

    while True:
        width = term_width()

        if active == "category":
            q = cat.strip()
            cands = fuzzy(categories, q)[:8] if q else []
        else:
            cands = []
        if cands:
            sel = max(0, min(sel, len(cands) - 1))
        else:
            sel = 0

        if active == "title":
            tline, col = field_view("title: ", title, tcur, width)
        else:
            tline = fit("title: " + title, width - 1)
            col = 0
        if active == "category":
            cline, col = field_view("category: ", cat, ccur, width)
        else:
            cline = fit("category: " + cat, width - 1)

        lines = [tline, cline]
        if error:
            lines.append(fit(error, width - 1))
        for i, item in enumerate(cands):
            label = fit(item, width - 2)
            if i == sel:
                lines.append("\x1b[7m" + label + "\x1b[0m")
            else:
                lines.append("  " + label)

        active_idx = 0 if active == "title" else 1
        screen.draw(lines, active_idx, col)

        key = read_key()
        if key is None:
            continue
        if key == "CTRL_C":
            return None
        if key == "ESC":
            if active == "category":
                active = "title"
                error = ""
                continue
            return None

        if key == "ENTER":
            if active == "title":
                if unquote(title) is None:
                    error = 'error: title 请用双引号包裹，例如 "My Title"'
                    continue
                error = ""
                active = "category"
                continue
            if cands:
                screen.finish(["title: " + title, "category: " + cands[sel]])
                return ("ok", (unquote(title), cands[sel]))
            error = "error: 输入内容以筛选 category"
            continue

        if active == "category" and cands and key in ("UP", "DOWN"):
            sel += -1 if key == "UP" else 1
            continue

        if active == "title":
            title, tcur, handled = handle_edit(key, title, tcur)
        else:
            cat, ccur, handled = handle_edit(key, cat, ccur)
        if handled:
            error = ""


def edit_name(screen, prompt, items, initial):
    text = initial
    cursor = len(text)
    sel = 0
    error = ""

    while True:
        width = term_width()
        value = loose_value(text)
        cands = fuzzy(items, value)[:8] if value else []
        if cands:
            sel = max(0, min(sel, len(cands) - 1))
        else:
            sel = 0

        line, col = field_view(prompt, text, cursor, width)
        lines = [line]
        if error:
            lines.append(fit(error, width - 1))
        for i, item in enumerate(cands):
            label = fit(item, width - 2)
            if i == sel:
                lines.append("\x1b[7m" + label + "\x1b[0m")
            else:
                lines.append("  " + label)
        screen.draw(lines, 0, col)

        key = read_key()
        if key is None:
            continue
        if key == "CTRL_C":
            return None
        if key == "ESC":
            return BACK
        if key == "ENTER":
            if cands:
                screen.finish([prompt + cands[sel]])
                return ("ok", cands[sel])
            if value:
                screen.finish([prompt + text])
                return ("ok", "NEW:" + value)
            error = "error: 请输入书名/电影名"
            continue
        if cands and key in ("UP", "DOWN"):
            sel += -1 if key == "UP" else 1
            continue

        text, cursor, handled = handle_edit(key, text, cursor)
        if handled:
            error = ""


def list_dirs(path):
    try:
        return sorted(
            d for d in os.listdir(path)
            if os.path.isdir(os.path.join(path, d)) and not d.startswith(".")
        )
    except OSError:
        return []


def run():
    screen = Screen()
    categories = list_dirs("content/posts")

    res = edit_title_category(screen, categories)
    if res is None:
        return None
    title, category = res[1]

    while category in ("book", "movie"):
        label = "book name: " if category == "book" else "movie name: "
        names = list_dirs(os.path.join("content/posts", category))
        res = edit_name(screen, label, names, "")
        if res is BACK:
            again = edit_title_category(screen, categories)
            if again is None:
                return None
            title, category = again[1]
            continue
        if res is None:
            return None
        return title, category, res[1]

    return title, category, ""


def main():
    out_fd = os.dup(1)
    try:
        tty_fd = os.open("/dev/tty", os.O_RDWR)
    except OSError:
        os.close(out_fd)
        return 2

    os.dup2(tty_fd, 0)
    os.dup2(tty_fd, 1)
    if tty_fd > 2:
        os.close(tty_fd)

    old_attrs = termios.tcgetattr(0)
    result = None
    try:
        tty.setcbreak(0)
        sys.stdout.write("（Esc 返回上一步 · Ctrl-C 取消）\n")
        sys.stdout.flush()
        result = run()
    finally:
        termios.tcsetattr(0, termios.TCSADRAIN, old_attrs)

    if result is None:
        os.close(out_fd)
        return 1

    title, category, name = result
    payload = f"TITLE\x1f{title}\nCATEGORY\x1f{category}\nNAME\x1f{name}\n"
    os.write(out_fd, payload.encode())
    os.close(out_fd)
    return 0


if __name__ == "__main__":
    sys.exit(main())
