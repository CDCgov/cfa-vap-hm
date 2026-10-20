#!/usr/bin/env python3
"""Toggle the optional home-manager modules of this repository.

modules/manifest.json declares what may be selected: each group is either
mutually exclusive (exactly one option) or a free combination of options.
The current selection lives in modules/state.json and is imported by
modules/profiles.nix on the next switch.

Interactive (zsh alias `hmt`):
    ./utils/module_tui.py

Scriptable:
    ./utils/module_tui.py --show
    ./utils/module_tui.py --set profile=lite
    ./utils/module_tui.py --set extras=r,azure
    ./utils/module_tui.py --reset
"""

from __future__ import annotations

import argparse
import copy
import json
import os
import subprocess
import sys
from pathlib import Path

MANIFEST_REL = Path("modules/manifest.json")
STATE_REL = Path("modules/state.json")

KEYS_HELP = (
    "Up/Down or j/k: move   Space/Enter: toggle   s: save   x: defaults   q: quit"
)


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
            for key in ("id", "title", "exclusive", "default", "options"):
                if key not in group:
                    raise ManifestError(f"group {group.get('id', group)!r} is missing '{key}'")
            if not isinstance(group["options"], list) or not group["options"]:
                raise ManifestError(f"group '{group['id']}' declares no options")
            option_ids = [option["id"] for option in group["options"]]
            if len(option_ids) != len(set(option_ids)):
                raise ManifestError(f"group '{group['id']}' has duplicate option ids")
            default = group["default"]
            if group["exclusive"]:
                if default not in option_ids:
                    raise ManifestError(
                        f"group '{group['id']}': default '{default}' is not one of {option_ids}"
                    )
            elif not isinstance(default, list) or any(i not in option_ids for i in default):
                raise ManifestError(
                    f"group '{group['id']}': default must be a list within {option_ids}"
                )
        return groups

    def _read_state(self) -> dict:
        try:
            data = json.loads((self.repo / STATE_REL).read_text())
        except FileNotFoundError:
            return {}
        except (OSError, json.JSONDecodeError) as exc:
            print(f"warning: ignoring unreadable {self.repo / STATE_REL}: {exc}", file=sys.stderr)
            return {}
        return data if isinstance(data, dict) else {}

    def _normalize(self, raw: dict) -> dict:
        """Coerce any state into selections the manifest allows."""
        state = {}
        for group in self.groups:
            option_ids = [option["id"] for option in group["options"]]
            selection = raw.get(group["id"], group["default"])
            if group["exclusive"]:
                state[group["id"]] = selection if selection in option_ids else group["default"]
            elif not isinstance(selection, list):
                state[group["id"]] = list(group["default"])
            else:
                state[group["id"]] = [
                    option["id"] for option in group["options"] if option["id"] in selection
                ]
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
        selection = self.state[group["id"]]
        if group["exclusive"]:
            return selection == option_id
        return option_id in selection

    def toggle(self, group_id: str, option_id: str) -> str:
        group = self.group(group_id)
        if group["exclusive"]:
            if self.state[group_id] == option_id:
                return f"{group['title']}: '{option_id}' is already selected (mutually exclusive)"
            self.state[group_id] = option_id
            return f"{group['title']} -> {option_id}"
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
            raise ManifestError(f"--set expects GROUP=OPTION[,OPTION...], got {assignment!r}")
        group_id, _, value = assignment.partition("=")
        group = self.group(group_id.strip())
        option_ids = [option["id"] for option in group["options"]]
        wanted = [item.strip() for item in value.split(",") if item.strip()]
        if group["exclusive"]:
            if len(wanted) != 1 or wanted[0] not in option_ids:
                raise ManifestError(
                    f"'{group_id}' is mutually exclusive; pick exactly one of: "
                    f"{', '.join(option_ids)}"
                )
            self.state[group["id"]] = wanted[0]
        else:
            unknown = [item for item in wanted if item not in option_ids]
            if unknown:
                raise ManifestError(
                    f"unknown option(s) for '{group_id}': {', '.join(unknown)} "
                    f"(valid: {', '.join(option_ids)})"
                )
            self.state[group["id"]] = [
                option["id"] for option in group["options"] if option["id"] in wanted
            ]
        selection = self.state[group["id"]]
        rendered = selection if group["exclusive"] else (", ".join(selection) or "(none)")
        return f"{group['title']} -> {rendered}"

    def reset(self) -> None:
        for group in self.groups:
            default = group["default"]
            self.state[group["id"]] = default if group["exclusive"] else list(default)

    def save(self) -> str:
        payload = {group["id"]: self.state[group["id"]] for group in self.groups}
        path = self.repo / STATE_REL
        tmp = path.with_name(path.name + ".tmp")
        tmp.write_text(json.dumps(payload, indent=2) + "\n")
        tmp.replace(path)
        self.saved = copy.deepcopy(self.state)
        note = self._stage_if_untracked(path)
        return f"saved {STATE_REL.as_posix()}{note} - run `hms` to apply"

    def _stage_if_untracked(self, path: Path) -> str:
        """The flake only sees git-tracked files; stage state.json when new."""
        try:
            probe = subprocess.run(
                ["git", "-C", str(self.repo), "status", "--porcelain", "--", str(path)],
                capture_output=True,
                text=True,
                timeout=15,
            )
        except (OSError, subprocess.TimeoutExpired):
            return ""
        if probe.returncode != 0 or not probe.stdout.startswith("??"):
            return ""
        added = subprocess.run(
            ["git", "-C", str(self.repo), "add", str(path)],
            capture_output=True,
            text=True,
            timeout=15,
        )
        if added.returncode == 0:
            return " (new file staged with git add)"
        return " (note: run `git add modules/state.json` so the flake sees it)"


def describe(cfg: Config) -> str:
    lines = [f"repo: {cfg.repo}"]
    for group in cfg.groups:
        mode = "mutually exclusive" if group["exclusive"] else "any combination"
        default = group["default"]
        if not group["exclusive"]:
            default = ", ".join(default) or "(none)"
        lines.append(f"{group['id']} [{mode}] {group['title']}: {group['description']}")
        lines.append(f"    default: {default}")
        for option in group["options"]:
            mark = "(*)" if group["exclusive"] else "[x]"
            if not cfg.is_selected(group, option["id"]):
                mark = "( )" if group["exclusive"] else "[ ]"
            lines.append(f"  {mark} {option['id']:<11} {option['description']}")
    lines.append(f"state: {STATE_REL.as_posix()} {'(unsaved changes)' if cfg.dirty else '(saved)'}")
    return "\n".join(lines)


def run_tui(cfg: Config) -> None:
    import curses

    try:
        curses.wrapper(tui_main, cfg)
    except KeyboardInterrupt:
        pass


def tui_main(stdscr, cfg: Config) -> None:
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
    except curses.error:
        pass  # monochrome terminal; plain attributes still work

    def put(y: int, x: int, text: str, attr: int = 0) -> None:
        height, width = stdscr.getmaxyx()
        if 0 <= y < height and 0 <= x < width:
            try:
                stdscr.addnstr(y, x, text, max(1, width - x - 1), attr)
            except curses.error:
                pass

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
            rows.append(("header", group))
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
        put(0, 0, " CFA VAP - home-manager module toggle ", header)
        put(1, 0, f" {cfg.repo}", curses.A_DIM)

        view_height = height - 5
        if cursor < top:
            top = cursor
        elif cursor >= top + view_height:
            top = cursor - view_height + 1
        for offset in range(view_height):
            index = top + offset
            if index >= len(rows):
                break
            row = rows[index]
            y = 2 + offset
            if row[0] == "header":
                group = row[1]
                mode = "choose one" if group["exclusive"] else "any combination"
                put(y, 0, f" {group['title']} ({mode})", header)
                continue
            _, group, option = row
            chosen = cfg.is_selected(group, option["id"])
            if group["exclusive"]:
                mark = "(*)" if chosen else "( )"
            else:
                mark = "[x]" if chosen else "[ ]"
            attr = cursor_attr if index == cursor else (selected_attr if chosen else curses.A_DIM)
            put(y, 2, f"{mark} {option['title']:<11} {option['description']}", attr)

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
    parser.add_argument("--show", action="store_true", help="print the selection and exit")
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
    args = parser.parse_args()

    try:
        cfg = Config(find_repo())
        if args.show:
            print(describe(cfg))
            return 0
        if not args.assignments and not args.reset:
            run_tui(cfg)
            return 0
        for assignment in args.assignments:
            print(cfg.apply_assignment(assignment))
        if args.reset:
            cfg.reset()
            print("reset every group to its manifest default")
        print(cfg.save())
        return 0
    except ManifestError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
