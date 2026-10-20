# Mozilla Firefox; an extra toggled via modules/manifest.json
# (toggle with `hmt` / utils/module_tui.py). Off by default to save space.
{ ... }:
{
  programs.firefox.enable = true;
}
