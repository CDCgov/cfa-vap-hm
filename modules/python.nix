# uv python manager; an extra toggled via modules/manifest.json
# (toggle with `hmt` / tui.py).
# Note: python313 itself lives in the core (home.nix) so `hmt` always works.
{ ... }:
{
  programs.uv.enable = true;
}
