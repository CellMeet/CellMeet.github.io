#!/usr/bin/env python3
"""行内模糊选择器：不占用整屏。

从标准输入读取候选（一行一个），在当前行提示输入，
候选实时显示在输入行下面。↑↓ 选择，Enter 确认，Esc 取消。
选择“新建”时输出 NEW:<输入内容>。
"""
import codecs
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


def dw(s):
    """终端显示宽度（中文算 2 列）。"""
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


class Ui:
    def __init__(self, prompt, allow_new, max_rows):
        self.prompt = prompt
        self.allow_new = allow_new
        self.max_rows = max_rows
        self.drawn = 0

    def write(self, s):
        sys.stdout.write(s)
        sys.stdout.flush()

    def render(self, query, cands, sel):
        width = term_width()
        out = ["\r\x1b[J"]
        shown, col = layout_line(self.prompt, query, len(query), width)
        out.append(shown)
        for i, item in enumerate(cands):
            label = fit(item, width - 2)
            out.append("\n")
            if i == sel:
                out.append("\x1b[7m" + label + "\x1b[0m")
            else:
                out.append("  " + label)
        if cands:
            out.append(f"\x1b[{len(cands)}A")
        out.append("\r")
        if col:
            out.append(f"\x1b[{col}C")
        self.write("".join(out))
        self.drawn = len(cands)

    def finish(self, text):
        out = ["\r\x1b[J", self.prompt + text + "\n"]
        self.write("".join(out))
        self.drawn = 0


def run(items, prompt, allow_new, max_rows, initial_query="", typed_only=False):
    ui = Ui(prompt, allow_new, max_rows)
    query = initial_query
    sel = 0
    decoder = codecs.getincrementaldecoder("utf-8")("replace")

    while True:
        q = norm(query)
        filtered = [it for it in items if score(q, it) < 99]
        filtered.sort(key=lambda it: (score(q, it), len(norm(it)), it.lower()))
        shown = [] if (typed_only and not query) else filtered[:max_rows]
        if not shown:
            sel = 0
        else:
            sel = max(0, min(sel, len(shown) - 1))
        ui.render(query, shown, sel)

        try:
            b = os.read(0, 1)
        except OSError:
            return None
        if not b:
            return None

        if b == b"\x1b":
            ready, _, _ = select.select([0], [], [], 0.02)
            if not ready:
                return None
            b2 = os.read(0, 1)
            if b2 == b"[":
                b3 = os.read(0, 1)
                if b3 == b"A":
                    sel -= 1
                elif b3 == b"B":
                    sel += 1
            continue

        if b in (b"\r", b"\n"):
            if shown:
                ui.finish(shown[sel])
                return shown[sel]
            text = query.strip()
            if text and allow_new:
                ui.finish(text)
                return "NEW:" + text
            continue

        if b in (b"\x7f", b"\x08"):
            query = query[:-1]
            sel = 0
            continue

        if b == b"\x03":
            return None

        ch = decoder.decode(b)
        if ch:
            query += ch
            sel = 0


def main():
    prompt = "输入"
    allow_new = False
    max_rows = 8
    initial_query = ""
    typed_only = False

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--prompt" and i + 1 < len(args):
            prompt = args[i + 1]
            i += 2
        elif a == "--allow-new":
            allow_new = True
            i += 1
        elif a == "--typed-only":
            typed_only = True
            i += 1
        elif a == "--query" and i + 1 < len(args):
            initial_query = args[i + 1]
            i += 2
        elif a == "--max" and i + 1 < len(args):
            try:
                max_rows = max(1, int(args[i + 1]))
            except ValueError:
                pass
            i += 2
        else:
            i += 1

    items = [line.rstrip("\n") for line in sys.stdin if line.strip()]

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
        result = run(items, prompt, allow_new, max_rows, initial_query, typed_only)
    finally:
        termios.tcsetattr(0, termios.TCSADRAIN, old_attrs)

    if result is None:
        os.close(out_fd)
        return 1

    os.write(out_fd, (result + "\n").encode())
    os.close(out_fd)
    return 0


if __name__ == "__main__":
    sys.exit(main())
