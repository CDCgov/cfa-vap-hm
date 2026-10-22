# Extra command-line tools; an extra toggled via modules/manifest.json
# (toggle with `hmt` / tui.py).
{ pkgs, ... }:
{
  home.packages = [ pkgs.lazydocker ];

  programs = {
    lazygit.enable = true;
    nushell.enable = true;
  };
}
