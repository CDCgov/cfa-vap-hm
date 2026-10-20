# Utility Scripts

Some scripts are useful to maintain outside of the `home-manager` ecosystem.
They are co-located here for conveneience.

## Module toggle TUI
Run (from the top level of this repository):
1. `python3 ./tui.py` (or the `hmt` alias) to toggle home-manager extras interactively.
    - The core in `home.nix` is always on; every extra (omz, python, editors, ai-tools, dev, r, rust, julia, azure, containers, sql, cli-tools) is independent.
    - Saving writes your overrides to the gitignored `modules/user-state.json`, which `modules/selection.nix` prefers over the tracked defaults in `modules/state.json`.
    - Press `a` to save, run `hms`, and close the TUI in one step.
    - A rainbow ASCII-art "CFA VAP HM" banner greets you (`figlet`/`lolcat` ship in the core).
2. Non-interactive variants: `--show`, `--set options=editors,omz`, `--set options=r --apply`, `--reset`.

## Drive Mounting scripts
Run (from the top level of this repository):
1. `bash ./utils/mount_vap_drives.sh` to mount your VAP network drives.
2. `bash ./utils/reset_vap_drives.sh` to unmount your network drives.
    - This script is called by the first as an optional first step for the user.
