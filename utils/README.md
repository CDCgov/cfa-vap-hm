# Utility Scripts

Some scripts are useful to maintain outside of the `home-manager` ecosystem.
They are co-located here for conveneience.

## Module toggle TUI
Run (from the top level of this repository):
1. `python3 ./utils/module_tui.py` (or the `hmt` alias) to toggle home-manager modules interactively.
    - Mutually exclusive groups (e.g. the `full` vs `lite` profile) always keep one selection; `extras` accepts any combination.
    - Saving writes `modules/state.json`, which `modules/profiles.nix` reads; apply with `hms`.
2. Non-interactive variants: `--show`, `--set profile=lite`, `--set extras=r,azure`, `--reset`.

## Drive Mounting scripts
Run (from the top level of this repository):
1. `bash ./utils/mount_vap_drives.sh` to mount your VAP network drives.
2. `bash ./utils/reset_vap_drives.sh` to unmount your network drives.
    - This script is called by the first as an optional first step for the user.
