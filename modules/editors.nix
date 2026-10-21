# Text editors; an extra toggled via modules/manifest.json
# (toggle with `hmt` / cfa-vap-tui).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    emacs
    neovim-unwrapped
  ];
}
