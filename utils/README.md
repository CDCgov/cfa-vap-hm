# Utility Scripts

Some scripts are useful to maintain outside of the `home-manager` ecosystem.
They are co-located here for conveneience.

## Module toggle TUI
Run (from the top level of this repository):
1. `nix run . -- --tui` (or the `hmt` alias) to toggle home-manager extras interactively.
    - The core in `home.nix`, including oh-my-zsh, is always on; every extra (python, editors, ai-tools, dev, r, rust, julia, azure, containers, sql, cli-tools) is independent.
    - Saving writes your overrides to the gitignored `modules/user-state.json`, which `modules/selection.nix` prefers over the tracked defaults in `modules/state.json`.
    - Press `a` to save, run `hms`, and close the TUI in one step.
    - A rainbow ASCII-art "CFA VAP HM" banner greets you (`figlet`/`lolcat` ship in the core).
2. Non-interactive variants: `--show`, `--set options=editors,python`, `--set options=r --apply`, `--reset`.

## Drive Mounting scripts
Run (from the top level of this repository):
1. `bash ./utils/mount_vap_drives.sh` to mount your VAP network drives.
2. `bash ./utils/reset_vap_drives.sh` to unmount your network drives.
    - This script is called by the first as an optional first step for the user.

## Docker Engine
Run `bash ./utils/install_docker_engine.sh` on Ubuntu, or select it in the TUI's
**Scripts (run once)** tier. It uses Docker's official apt repository, installs
Engine, Buildx and Compose, starts Docker, verifies it with hello-world, and adds
your user to the docker group. Log out and back in afterward, or run
`newgrp docker` manually; the script does not replace your shell.

All TUI scripts start unchecked and run after Home Manager applies successfully.
Script selections are never persisted. The drive utilities retain their existing prompts.
