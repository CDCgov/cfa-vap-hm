# Legacy Imperative Scripts

The scripts in this directory are imperative rather than declarative. They are not included in the nix-managed `home-manager` system that serves as the core of this repository. However, these scripts may nonetheless be useful (for now) as we work out the kinks of including their functionality into the `home-manager` ecoystem.

## Mounting (and unmounting) VAP network drive
Run `bash ./scripts/setup-fstab.sh` to mount network drives (you can also run `make drives`).
- You can also run `bash ./scripts/reset_fstab.sh` to remove your drive mounts. 
- These are not part of our `home-manager` setup - it's included in this repository for convenience.
- These scripts can only be run within a Linux or WSL environment on the CFA VAP - they will not work outside of it.
