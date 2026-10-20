# Language/build toolchain; an extra toggled via modules/manifest.json
# (toggle with `hmt` / utils/module_tui.py).
# Note: python313, ruff and the repo linters live in the core (home.nix).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gcc # includes gcc and g++
    gnumake
    pkg-config # discovers library compiler and linker flags
    nodejs
  ];
}
