# uv python manager; an extra toggled via modules/manifest.json
# (toggle with `hmt` / cfa-vap-tui).
# Note: python313 itself lives in the core (home.nix).
{ ... }:
{
  programs.uv.enable = true;
}
