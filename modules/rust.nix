# Rust toolchain; an extra toggled via modules/manifest.json
# (toggle with `hmt` / utils/module_tui.py).
# rustup manages the toolchain (rustc, cargo, rustfmt, clippy); the
# standalone cargo/rustc also come along so a fresh shell works without
# running `rustup default` first.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rustup
    cargo
    rustc
    rustfmt
    clippy
  ];
}
