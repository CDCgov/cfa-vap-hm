# Text editors; an extra toggled via modules/manifest.json
# (toggle with `hmt` / tui.py).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    emacs
    neovim-unwrapped
  ];
}
