# Julia; an extra toggled via modules/manifest.json
# (toggle with `hmt` / tui.py).
# juliaup is not packaged in this nixpkgs pin, so we install the
# prebuilt julia-bin instead of the source build.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    julia-bin
  ];
}
