# Rust toolchain; an extra toggled via modules/manifest.json
# (toggle with `hmt` / tui.py).
# rustup manages the toolchain and provides the cargo/rustc/rustfmt/clippy
# shims, so the standalone packages are intentionally not installed (they would
# collide with rustup's shims in the profile).
{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    rustup
  ];

  # If there's no default rustup channel, default to stable. will not override an existing channel
  home.activation.initializeRustToolchain = lib.hm.dag.entryAfter [ "installPackages" ] ''
    if ! ${pkgs.rustup}/bin/rustup default >/dev/null 2>&1; then
      run ${pkgs.rustup}/bin/rustup default stable
    fi
  '';
}
