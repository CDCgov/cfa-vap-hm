#!/usr/bin/env python3
"""Toggle the optional home-manager extras of this repository.

The core environment lives in home.nix; every optional extra in
modules/manifest.json maps to a module file under modules/. The tracked
modules/state.json holds the default selection; saving writes your
overrides to the gitignored modules/user-state.json, which takes
precedence (read by modules/selection.nix on the next switch).

Interactive (zsh alias `hmt`):
    ./tui.py
    # key `a` saves, runs `hms`, and exits - no need to quit first

Scriptable:
    ./tui.py --show
    ./tui.py --set options=editors,omz
    ./tui.py --set options=r --apply
    ./tui.py --reset
"""

from __future__ import annotations

import argparse
import copy
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

MANIFEST_REL = Path("modules/manifest.json")
USER_STATE_REL = Path("modules/user-state.json")
DEFAULT_STATE_REL = Path("modules/state.json")

KEYS_HELP = "j/k/arrows: move  Space: toggle  s: save  x: defaults  "

# The apply-and-quit key is the primary action, so it is shown in its own
# brighter segment; the remaining keys stay dim.
KEYS_HELP_PRIMARY = "a: apply & quit"
KEYS_HELP_TAIL = "  q: quit"

# curses colour-pair ids 1-4 are used by the chrome; the rainbow art's shades
# start here.
RAINBOW_PAIR_BASE = 8

_ANSI_TRUECOLOR = re.compile(r"\x1b\[38;2;(\d+);(\d+);(\d+)m")
_ANSI_RESET = re.compile(r"\x1b\[(?:0|39)m")


def _rgb_to_xterm256(r: int, g: int, b: int) -> int:
    """Map a 24-bit colour onto the nearest xterm-256 palette index."""
    if r == g == b:
        if r < 8:
            return 16
        if r > 248:
            return 231
        return 232 + round((r - 8) / 247 * 24)
    levels = (0, 95, 135, 175, 215, 255)
    ri = min(range(6), key=lambda i: abs(levels[i] - r))
    gi = min(range(6), key=lambda i: abs(levels[i] - g))
    bi = min(range(6), key=lambda i: abs(levels[i] - b))
    return 16 + 36 * ri + 6 * gi + bi


def parse_ansi_cells(art: str) -> list[list[tuple[str, int | None]]]:
    """Turn lolcat-coloured text into per-line lists of (char, colour) cells."""
    lines: list[list[tuple[str, int | None]]] = []
    for raw in art.rstrip("\n").splitlines():
        cells: list[tuple[str, int | None]] = []
        colour: int | None = None
        index = 0
        while index < len(raw):
            match = _ANSI_TRUECOLOR.match(raw, index)
            if match:
                colour = _rgb_to_xterm256(*(int(v) for v in match.groups()))
                index = match.end()
                continue
            if _ANSI_RESET.match(raw, index):
                colour = None
                index = _ANSI_RESET.match(raw, index).end()
                continue
            if raw[index] == "\x1b":  # any other escape - skip to its final byte
                index += 1
                while index < len(raw) and not raw[index].isalpha():
                    index += 1
                index += 1
                continue
            cells.append((raw[index], colour))
            index += 1
        lines.append(cells)
    return lines


def lolcat(text: str) -> str:
    """Pipe text through `lolcat --force --seed 1`, or return it unchanged."""
    tool = shutil.which("lolcat")
    if tool is None:
        return text
    try:
        return subprocess.run(
            [tool, "--force", "--seed", "1"],
            input=text,
            capture_output=True,
            text=True,
            check=True,
        ).stdout
    except (OSError, subprocess.CalledProcessError):
        return text


def title_lines() -> list[list[tuple[str, int | None]]]:
    """Rainbow ASCII-art banner for the TUI title.

    `figlet -f slant` renders the banner and lolcat colours it; when figlet
    is unavailable we fall back to plain, one-colour text.
    """
    banner = "CFA VAP  HM"
    figlet = shutil.which("figlet")
    if figlet is None:
        return [[(ch, None) for ch in f" {banner} "]]
    try:
        art = subprocess.run(
            [figlet, "-f", "slant", banner],
            capture_output=True,
            text=True,
            check=True,
        ).stdout
    except (OSError, subprocess.CalledProcessError):
        return [[(ch, None) for ch in f" {banner} "]]
    return parse_ansi_cells(lolcat(art))


class ManifestError(Exception):
    """The manifest or a --set assignment is unusable."""


def find_repo() -> Path:
    override = os.environ.get("HM_DIR")
    if override:
        return Path(override).expanduser().resolve()
    here = Path(__file__).resolve().parent.parent
    if (here / MANIFEST_REL).is_file():
        return here
    return Path.home() / ".config" / "home-manager"


class Config:
    """The manifest plus the current (normalized) module selection."""

    def __init__(self, repo: Path):
        self.repo = repo
        self.groups = self._read_manifest()
        self.state_source: Path | None = None
        self.saved = self._normalize(self._read_state())
        self.state = copy.deepcopy(self.saved)

    def _read_manifest(self) -> list[dict]:
        path = self.repo / MANIFEST_REL
        try:
            data = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError) as exc:
            raise ManifestError(f"cannot read {path}: {exc}") from exc
        groups = data.get("groups")
        if not isinstance(groups, list) or not groups:
            raise ManifestError(f"{path} must declare a non-empty 'groups' list")
        for group in groups:
            for key in ("id", "title", "description", "default", "options"):
                if key not in group:
                    raise ManifestError(
                        f"group {group.get('id', group)!r} is missing '{key}'"
                    )
            if not isinstance(group["options"], list) or not group["options"]:
                raise ManifestError(f"group '{group['id']}' declares no options")
            option_ids = [option["id"] for option in group["options"]]
            if len(option_ids) != len(set(option_ids)):
                raise ManifestError(f"group '{group['id']}' has duplicate option ids")
            default = group["default"]
            if not isinstance(default, list) or any(
                i not in option_ids for i in default
            ):
                raise ManifestError(
                    f"group '{group['id']}': default must be a list within {option_ids}"
                )
        return groups

    def _read_state(self) -> dict:
        """Read user-state.json (personal overrides) or fall back to state.json."""
        for rel in (USER_STATE_REL, DEFAULT_STATE_REL):
            path = self.repo / rel
            try:
                data = json.loads(path.read_text())
            except FileNotFoundError:
                continue
            except (OSError, json.JSONDecodeError) as exc:
                print(f"warning: ignoring unreadable {path}: {exc}", file=sys.stderr)
                continue
            self.state_source = rel
            return data if isinstance(data, dict) else {}
        return {}

    def _normalize(self, raw: dict) -> dict:
        """Coerce any state into selections the manifest allows, falling back
        to the group's default when the state holds something unusable."""
        state = {}
        for group in self.groups:
            option_ids = [option["id"] for option in group["options"]]
            selection = raw.get(group["id"], group["default"])
            if not isinstance(selection, list) or not all(
                isinstance(i, str) and i in option_ids for i in selection
            ):
                selection = group["default"]
            state[group["id"]] = [i for i in option_ids if i in selection]
        return state

    def group(self, group_id: str) -> dict:
        for group in self.groups:
            if group["id"] == group_id:
                return group
        valid = ", ".join(group["id"] for group in self.groups)
        raise ManifestError(f"unknown group {group_id!r} (valid: {valid})")

    @property
    def dirty(self) -> bool:
        return self.state != self.saved

    def is_selected(self, group: dict, option_id: str) -> bool:
        return option_id in self.state[group["id"]]

    def toggle(self, group_id: str, option_id: str) -> str:
        group = self.group(group_id)
        selected = self.state[group_id]
        if option_id in selected:
            selected.remove(option_id)
            return f"{group['title']}: removed '{option_id}'"
        selected.append(option_id)
        # Keep selections in manifest order so state.json stays tidy.
        self.state[group_id] = [
            option["id"] for option in group["options"] if option["id"] in selected
        ]
        return f"{group['title']}: added '{option_id}'"

    def apply_assignment(self, assignment: str) -> str:
        """Apply a `GROUP=OPTION[,OPTION]` assignment from --set."""
        if "=" not in assignment:
            raise ManifestError(
                f"--set expects GROUP=OPTION[,OPTION...], got {assignment!r}"
            )
        group_id, _, value = assignment.partition("=")
        group = self.group(group_id.strip())
        option_ids = [option["id"] for option in group["options"]]
        wanted = [item.strip() for item in value.split(",") if item.strip()]
        unknown = [item for item in wanted if item not in option_ids]
        if unknown:
            raise ManifestError(
                f"unknown option(s) for '{group_id}': {', '.join(unknown)} "
                f"(valid: {', '.join(option_ids)})"
            )
        self.state[group["id"]] = [
            option["id"] for option in group["options"] if option["id"] in wanted
        ]
        rendered = ", ".join(self.state[group["id"]]) or "(none)"
        return f"{group['title']} -> {rendered}"

    def reset(self) -> None:
        for group in self.groups:
            self.state[group["id"]] = list(group["default"])

    def save(self) -> str:
        """Write the selection to user-state.json (takes over from state.json)."""
        payload = {group["id"]: self.state[group["id"]] for group in self.groups}
        path = self.repo / USER_STATE_REL
        tmp = path.with_name(path.name + ".tmp")
        tmp.write_text(json.dumps(payload, indent=2) + "\n")
        tmp.replace(path)
        self.saved = copy.deepcopy(self.state)
        self.state_source = USER_STATE_REL
        return f"saved {USER_STATE_REL.as_posix()} - run `hms` to apply"


def switch_command(repo: Path) -> list[str] | None:
    """The `hms` alias as a command; None when no runner is on PATH."""
    if shutil.which("home-manager"):
        return ["home-manager", "switch", "--flake", f"{repo}/", "--impure"]
    if shutil.which("nix"):
        return ["nix", "run", str(repo), "--", "switch", "--impure"]
    return None


def apply_config(cfg: Config) -> int:
    """Save the selection, run `hms` on the restored terminal, then exit."""
    if cfg.dirty:
        print(cfg.save())
    command = switch_command(cfg.repo)
    if command is None:
        print(
            "error: neither `home-manager` nor `nix` is on PATH - run `hms` yourself.",
            file=sys.stderr,
        )
        return 1
    print(f"Applying: {' '.join(command)}", flush=True)
    try:
        code = subprocess.call(command)
    except KeyboardInterrupt:
        print("\nInterrupted - the switch did not finish.", file=sys.stderr)
        return 130
    if code == 0:
        print("Applied - your environment now matches your saved selection.")
        return 0
    print(
        f"home-manager switch failed (exit {code}). Your selection is still saved; "
        "fix the error above and run `hms` to retry.",
        file=sys.stderr,
    )
    return code if code > 0 else 1


def describe(cfg: Config) -> str:
    lines = [f"repo: {cfg.repo}"]
    for group in cfg.groups:
        default = ", ".join(group["default"]) or "(none)"
        lines.append(f"{group['id']}: {group['title']} - {group['description']}")
        lines.append(f"    default: {default}")
        for option in group["options"]:
            mark = "[x]" if cfg.is_selected(group, option["id"]) else "[ ]"
            lines.append(f"  {mark} {option['id']:<11} {option['description']}")
    if cfg.state_source == USER_STATE_REL:
        origin = "personal overrides"
    elif cfg.state_source == DEFAULT_STATE_REL:
        origin = "tracked defaults"
    else:
        origin = "manifest defaults"
    dirty = " - unsaved changes" if cfg.dirty else ""
    lines.append(
        f"state: {(cfg.state_source or DEFAULT_STATE_REL).as_posix()} ({origin}){dirty}"
    )
    return "\n".join(lines)


def run_tui(cfg: Config) -> str | None:
    """Run the interactive TUI; return "apply" when the user asked to apply."""
    import curses

    try:
        return curses.wrapper(tui_main, cfg)
    except KeyboardInterrupt:
        return None


def tui_main(stdscr, cfg: Config) -> str | None:
    import curses

    stdscr.keypad(True)
    try:
        curses.curs_set(0)
    except curses.error:
        pass
    header = curses.A_BOLD
    selected_attr = curses.A_BOLD
    status_attr = curses.A_BOLD
    cursor_attr = curses.A_REVERSE
    color_supported = False
    try:
        curses.start_color()
        curses.use_default_colors()
        curses.init_pair(1, curses.COLOR_CYAN, -1)
        curses.init_pair(2, curses.COLOR_GREEN, -1)
        curses.init_pair(3, curses.COLOR_YELLOW, -1)
        curses.init_pair(4, curses.COLOR_BLACK, curses.COLOR_WHITE)
        header = curses.color_pair(1) | curses.A_BOLD
        selected_attr = curses.color_pair(2)
        status_attr = curses.color_pair(3)
        cursor_attr = curses.color_pair(4)
        color_supported = curses.COLORS >= 256
    except curses.error:
        pass  # monochrome terminal; plain attributes still work

    # Pre-render the rainbow title, then map every xterm-256 colour it uses to
    # a curses colour pair once, so it can be painted without re-registering
    # pairs on each frame.
    title = title_lines()
    rainbow_pairs: dict[int, int] = {}
    if color_supported:
        used = sorted(
            {
                colour
                for art in (title,)
                for line in art
                for _, colour in line
                if colour is not None
            }
        )
        for slot, colour in enumerate(used, start=RAINBOW_PAIR_BASE):
            try:
                curses.init_pair(slot, colour, -1)
            except curses.error:
                continue
            rainbow_pairs[colour] = curses.color_pair(slot)

    def put(y: int, x: int, text: str, attr: int = 0) -> None:
        height, width = stdscr.getmaxyx()
        if 0 <= y < height and 0 <= x < width:
            try:
                stdscr.addnstr(y, x, text, max(1, width - x - 1), attr)
            except curses.error:
                pass

    def put_cells(y: int, x: int, cells: list[tuple[str, int | None]]) -> None:
        """Draw a pre-coloured art line, one run per colour, clipped to width."""
        height, width = stdscr.getmaxyx()
        if not (0 <= y < height):
            return
        column = x
        index = 0
        while index < len(cells) and column < width - 1:
            colour = cells[index][1]
            attr = (
                rainbow_pairs.get(colour, selected_attr)
                if colour is not None
                else selected_attr
            )
            run = ""
            while index < len(cells) and cells[index][1] == colour:
                run += cells[index][0]
                index += 1
            run = run[: width - 1 - column]
            try:
                stdscr.addnstr(y, column, run, len(run), attr)
            except curses.error:
                pass
            column += len(run)

    rows: list[tuple] = []
    option_rows: list[int] = []
    cursor = 0
    top = 0
    message = ""
    pending_quit = False

    def rebuild() -> None:
        nonlocal rows, option_rows, cursor
        rows = []
        for group in cfg.groups:
            rows.append(("blank",))
            rows.append(("header", group))
            rows.append(("blank",))
            if group.get("id") == "options":
                defaults = set(group.get("default", []))
                first_default = None
                for idx, opt in enumerate(group["options"]):
                    if opt["id"] in defaults:
                        first_default = idx
                        break
                first_nondefault = None
                for idx, opt in enumerate(group["options"]):
                    if opt["id"] not in defaults:
                        first_nondefault = idx
                        break
                for i, opt in enumerate(group["options"]):
                    if first_default == i:
                        rows.append(("separator",))
                        rows.append(("subtitle", "Core tools (on by default)"))
                    if first_nondefault == i:
                        rows.append(("separator",))
                        rows.append(("subtitle", "Optional (off by default)"))
                    rows.append(("option", group, opt))
            else:
                for option in group["options"]:
                    rows.append(("option", group, option))
        option_rows = [index for index, row in enumerate(rows) if row[0] == "option"]
        if cursor not in option_rows:
            cursor = option_rows[0]

    def draw() -> None:
        nonlocal top
        stdscr.erase()
        height, width = stdscr.getmaxyx()
        if height < 8 or width < 46:
            put(0, 0, "Terminal too small - resize to at least 46x8.")
            stdscr.refresh()
            return

        # Rainbow ASCII-art title, left-justified. If it would leave too little
        # room for the list, fall back to a plain one-line banner.
        title_width = max((len(line) for line in title), default=0)
        title_height = len(title)
        banner_fits = (
            title_width + 2 <= width
            and height - title_height >= 14
            and title_height > 1
        )
        if banner_fits:
            for offset, line in enumerate(title):
                put_cells(offset, 0, line)
            header_y = title_height
        else:
            put(0, 0, " CFA VAP - home-manager module toggle ", header)
            header_y = 1
        put(header_y, 0, f" {cfg.repo}", curses.A_DIM)

        list_top = header_y + 1
        # The choices fill the full width; the list scrolls if there are more
        # rows than fit above the footer.
        footer_top = height - 3
        full_view_height = footer_top - list_top
        list_x = 0
        list_limit = width - 1
        view_height = full_view_height

        if view_height <= 0:
            stdscr.refresh()
            return
        if cursor < top:
            top = cursor
        elif cursor >= top + view_height:
            top = cursor - view_height + 1
        for offset in range(view_height):
            index = top + offset
            if index >= len(rows):
                break
            row = rows[index]
            y = list_top + offset
            if row[0] == "blank":
                continue
            if row[0] == "separator":
                sep = "─" * (width - list_x)
                put(y, list_x, sep[:list_limit], curses.A_DIM)
                continue
            if row[0] == "subtitle":
                put(
                    y,
                    list_x + 2,
                    row[1][: list_limit - 2],
                    curses.A_DIM | curses.A_BOLD,
                )
                continue
            if row[0] == "header":
                group = row[1]
                put(
                    y,
                    list_x,
                    f" {group['title']} - {group['description']}"[:list_limit],
                    header,
                )
                continue
            _, group, option = row
            chosen = cfg.is_selected(group, option["id"])
            mark = "[x]" if chosen else "[ ]"
            attr = (
                cursor_attr
                if index == cursor
                else (selected_attr if chosen else curses.A_DIM)
            )
            put(
                y,
                list_x + 2,
                f"{mark} {option['title']:<17} {option['description']}"[
                    : list_limit - 2
                ],
                attr,
            )

        _, group, option = rows[cursor]
        put(
            height - 3,
            0,
            f"{group['id']}/{option['id']} -> {option['path']}: {option['description']}",
            curses.A_DIM,
        )
        if message:
            put(height - 2, 0, message, status_attr)
        elif cfg.dirty:
            put(height - 2, 0, "Unsaved changes - press s to save them.", status_attr)
        else:
            put(height - 2, 0, "Saved. Run `hms` after saving to apply.", curses.A_DIM)
        put(height - 1, 0, KEYS_HELP, curses.A_DIM)
        x = len(KEYS_HELP)
        if cfg.dirty and color_supported:
            primary_attr = curses.color_pair(2) | curses.A_DIM
        else:
            primary_attr = curses.A_DIM
        put(height - 1, x, KEYS_HELP_PRIMARY, primary_attr)
        put(height - 1, x + len(KEYS_HELP_PRIMARY), KEYS_HELP_TAIL, curses.A_DIM)
        stdscr.refresh()

    rebuild()
    while True:
        draw()
        key = stdscr.getch()
        if key == curses.KEY_RESIZE:
            continue
        if key in (ord("q"), ord("Q")):
            if cfg.dirty and not pending_quit:
                pending_quit = True
                message = "Unsaved changes - press q again to quit, or s to save first."
                continue
            break
        pending_quit = False
        if key in (curses.KEY_UP, ord("k")):
            message = ""
            position = option_rows.index(cursor)
            cursor = option_rows[max(0, position - 1)]
        elif key in (curses.KEY_DOWN, ord("j")):
            message = ""
            position = option_rows.index(cursor)
            cursor = option_rows[min(len(option_rows) - 1, position + 1)]
        elif key in (curses.KEY_ENTER, 10, 13, ord(" ")):
            _, group, option = rows[cursor]
            message = cfg.toggle(group["id"], option["id"])
        elif key == ord("s"):
            message = cfg.save()
        elif key == ord("a"):
            # Save + run `hms` happen after curses.wrapper has restored the
            # terminal (see apply_config), so switch output is fully usable.
            return "apply"
        elif key == ord("x"):
            cfg.reset()
            message = "Reset every group to its manifest default (not saved yet)."
        else:
            message = ""


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--show", action="store_true", help="print the selection and exit"
    )
    parser.add_argument(
        "--set",
        dest="assignments",
        action="append",
        default=[],
        metavar="GROUP=OPTION[,OPTION]",
        help="set a group's selection (repeatable); implies saving",
    )
    parser.add_argument(
        "--reset",
        action="store_true",
        help="reset every group to its manifest default; implies saving",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="run home-manager switch (`hms`) afterwards and exit",
    )
    args = parser.parse_args()

    try:
        cfg = Config(find_repo())
        if args.show:
            print(describe(cfg))
            return 0
        if not args.assignments and not args.reset and not args.apply:
            outcome = run_tui(cfg)
            return apply_config(cfg) if outcome == "apply" else 0
        for assignment in args.assignments:
            print(cfg.apply_assignment(assignment))
        if args.reset:
            cfg.reset()
            print("reset every group to its manifest default")
        if args.assignments or args.reset:
            print(cfg.save())
        if args.apply:
            return apply_config(cfg)
        return 0
    except ManifestError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
