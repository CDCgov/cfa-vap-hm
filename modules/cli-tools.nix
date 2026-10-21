# Extra command-line tools; an extra toggled via modules/manifest.json
# (toggle with `hmt` / cfa-vap-tui).
{ pkgs, ... }:
{
  home.packages = [ pkgs.lazydocker ];

  programs = {
    lazygit.enable = true;
    nushell.enable = true;
  };
}
