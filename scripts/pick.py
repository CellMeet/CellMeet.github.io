#!/usr/bin/env python3
"""终端模糊选择器：↑↓ 移动，输入筛选，Enter 确认，Esc 取消。

从标准输入读取候选（一行一个）。
输出选中的候选；选择“新建”时输出 NEW:<输入的筛选词>。
"""
import os
import sys
import curses
import locale

# 尽量使用 UTF-8，避免中文在部分终端里显示成空白
for _loc in ("C.UTF-8", "en_US.UTF-8", "zh_CN.UTF-8", ""):
    try:
        locale.setlocale(locale.LC_ALL, _loc)
        break
    except locale.Error:
        continue


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


def pick(stdscr, items, prompt, new_label, allow_new, initial_query=""):
    query = initial_query
    sel = 0

    while True:
        q = norm(query)
        filtered = [it for it in items if score(q, it) < 99]
        filtered.sort(key=lambda it: (score(q, it), len(norm(it)), it.lower()))
        rows = list(filtered)
        if allow_new:
            rows.append(None)

        if not rows:
            return None
        sel = max(0, min(sel, len(rows) - 1))

        # ---- 计算布局并绘制 ----
        stdscr.erase()
        h, w = stdscr.getmaxyx()
        title = f"{prompt}   Up/Down select · Enter confirm · Esc cancel"
        stdscr.addnstr(0, 0, title, max(1, w - 1), curses.A_BOLD)
        stdscr.addnstr(1, 0, "› " + query, max(1, w - 1))

        visible = max(1, h - 3)
        start = 0
        if sel >= visible:
            start = sel - visible + 1
        for idx in range(start, min(len(rows), start + visible)):
            item = rows[idx]
            if item is None:
                label = new_label
                if query.strip():
                    label += f"「{query.strip()}」"
            else:
                label = item
            attr = curses.A_REVERSE if idx == sel else curses.A_NORMAL
            stdscr.addnstr(2 + idx - start, 2, label, max(1, w - 3), attr)
        stdscr.refresh()

        # ---- 按键 ----
        try:
            ch = stdscr.get_wch()
        except curses.error:
            continue

        if isinstance(ch, str):
            if ch in ("\n", "\r"):
                break
            if ch == "\x1b":
                return None
            if ch in ("\x7f", "\b"):
                if query:
                    query = query[:-1]
                    sel = 0
            elif ch.isprintable():
                query += ch
                sel = 0
        else:
            if ch == curses.KEY_UP:
                sel -= 1
            elif ch == curses.KEY_DOWN:
                sel += 1
            elif ch == curses.KEY_PPAGE:
                sel -= visible
            elif ch == curses.KEY_NPAGE:
                sel += visible
            elif ch in (curses.KEY_BACKSPACE, 8, 127):
                if query:
                    query = query[:-1]
                    sel = 0
            elif ch in (curses.KEY_ENTER, 10, 13):
                break
            elif ch == 27:
                return None

    item = rows[sel]
    if item is None:
        return "NEW:" + query.strip()
    return item


def main():
    prompt = "Select"
    new_label = "+ New"
    allow_new = True
    initial_query = ""

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--prompt" and i + 1 < len(args):
            prompt = args[i + 1]
            i += 2
        elif a == "--new-label" and i + 1 < len(args):
            new_label = args[i + 1]
            i += 2
        elif a == "--query" and i + 1 < len(args):
            initial_query = args[i + 1]
            i += 2
        elif a == "--no-new":
            allow_new = False
            i += 1
        else:
            i += 1

    items = [line.rstrip("\n") for line in sys.stdin if line.strip()]

    # 候选来自管道，但键盘输入和画面要来自真正的终端
    out_fd = os.dup(1)  # 保存原来的 stdout，用于把结果回传给 new.sh
    try:
        tty_fd = os.open("/dev/tty", os.O_RDWR)
    except OSError:
        os.close(out_fd)
        return 1
    os.dup2(tty_fd, 0)
    os.dup2(tty_fd, 1)
    if tty_fd > 2:
        os.close(tty_fd)

    try:
        result = curses.wrapper(pick, items, prompt, new_label, allow_new, initial_query)
    except Exception:
        os.close(out_fd)
        return 2
    if result is None:
        os.close(out_fd)
        return 1
    os.write(out_fd, (result + "\n").encode())
    os.close(out_fd)
    return 0


if __name__ == "__main__":
    sys.exit(main())
