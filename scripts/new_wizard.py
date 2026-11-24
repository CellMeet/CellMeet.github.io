#!/usr/bin/env python3
"""交互式新建内容向导。

流程：title -> category ->（book/movie 时）book name / movie name
- 行内输入，候选显示在输入行下面，不占整屏
- 候选默认不显示，开始输入后才出现
- title 和 book/movie 名必须用双引号包裹
- category 或 name 步骤按 Esc 可返回上一步修改
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
        return shutil.get_terminal_size((80, 24)).columns
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


def layout_line(prompt, text, cursor, width):
    full = prompt + text
    if dw(full) <= width - 1:
        return full, dw(prompt + text[:cursor])
    avail = width - 2 - dw(prompt + "…")
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
    shown = prompt + "…" + tail
    if cursor >= start:
        col = dw(prompt + "…" + text[start:cursor])
    else:
        col = dw(prompt + "…")
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


class Ui:
    def __init__(self):
        self.drawn = 0

    def write(self, s):
        sys.stdout.write(s)
        sys.stdout.flush()

    def render(self, prompt, text, cursor, cands, sel, error):
        width = term_width()
        out = ["\r\x1b[J"]
        shown, col = layout_line(prompt, text, cursor, width)
        out.append(shown)
        lines = []
        if error:
            lines.append(fit(error, width - 1))
        for i, item in enumerate(cands):
            label = fit(item, width - 2)
            if i == sel:
                lines.append("\x1b[7m" + label + "\x1b[0m")
            else:
                lines.append("  " + label)
        for line in lines:
            out.append("\n" + line)
        if lines:
            out.append(f"\x1b[{len(lines)}A")
        out.append("\r")
        if col:
            out.append(f"\x1b[{col}C")
        self.write("".join(out))
        self.drawn = len(lines)

    def finish(self, prompt, text):
        out = ["\r\x1b[J", prompt + text + "\n"]
        self.write("".join(out))
        self.drawn = 0


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


def edit_step(ui, prompt, initial, items, mode, back_allowed):
    """mode: title / category / name"""
    text = initial
    cursor = len(text)
    sel = 0
    error = ""

    while True:
        if mode == "category":
            q = text.strip()
            cands = fuzzy(items, q)[:8] if q else []
        elif mode == "name":
            inner = unquote(text)
            q = (inner or "").strip()
            cands = fuzzy(items, q)[:8] if q else []
        else:
            cands = []

        if cands:
            sel = max(0, min(sel, len(cands) - 1))
        else:
            sel = 0

        ui.render(prompt, text, cursor, cands, sel, error)

        key = read_key()
        if key is None:
            continue

        if key == "CTRL_C":
            return None
        if key == "ESC":
            if back_allowed:
                return BACK
            return None

        if key == "ENTER":
            if mode == "title":
                val = unquote(text)
                if val is None:
                    error = 'error: 请用双引号包裹，例如 "My Title"'
                    continue
                ui.finish(prompt, text)
                return ("ok", val)
            if mode == "category":
                if cands:
                    ui.finish(prompt, cands[sel])
                    return ("ok", cands[sel])
                error = "error: 输入内容以筛选现有类型"
                continue
            if mode == "name":
                val = unquote(text)
                if val is None:
                    error = 'error: 请用双引号包裹，例如 "I Feel Bad About My Neck"'
                    continue
                if cands:
                    ui.finish(prompt, '"' + cands[sel] + '"')
                    return ("ok", cands[sel])
                ui.finish(prompt, text)
                return ("ok", "NEW:" + val)

        if key == "UP":
            sel -= 1
            continue
        if key == "DOWN":
            sel += 1
            continue
        if key == "LEFT":
            cursor = max(0, cursor - 1)
            continue
        if key == "RIGHT":
            cursor = min(len(text), cursor + 1)
            continue
        if key == "HOME":
            cursor = 0
            continue
        if key == "END":
            cursor = len(text)
            continue
        if key == "CTRL_U":
            text = ""
            cursor = 0
            error = ""
            continue
        if key == "BS":
            if cursor > 0:
                text = text[: cursor - 1] + text[cursor:]
                cursor -= 1
            continue
        if key == "DEL":
            if cursor < len(text):
                text = text[:cursor] + text[cursor + 1:]
            continue

        if len(key) >= 1 and key.isprintable():
            text = text[:cursor] + key + text[cursor:]
            cursor += len(key)
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
    ui = Ui()
    categories = list_dirs("content/posts")

    # 标题
    res = edit_step(ui, "title: ", "", [], "title", False)
    if res is None:
        return None
    title = res[1]

    while True:
        # 类型
        res = edit_step(ui, "category: ", "", categories, "category", True)
        if res is BACK:
            res = edit_step(ui, "title: ", f'"{title}"', [], "title", False)
            if res is None:
                return None
            title = res[1]
            continue
        if res is None:
            return None
        category = res[1]

        if category not in ("book", "movie"):
            return title, category, ""

        # 书名 / 电影名
        label = "book name: " if category == "book" else "movie name: "
        names = list_dirs(os.path.join("content/posts", category))
        res = edit_step(ui, label, "", names, "name", True)
        if res is BACK:
            continue
        if res is None:
            return None
        return title, category, res[1]


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
