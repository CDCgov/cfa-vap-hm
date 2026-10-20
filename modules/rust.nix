# Rust toolchain; an extra toggled via modules/manifest.json
# (toggle with `hmt` / tui.py).
# rustup manages the toolchain and provides the cargo/rustc/rustfmt/clippy
# shims, so the standalone packages are intentionally not installed (they would
# collide with rustup's shims in the profile).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rustup
  ];
}
