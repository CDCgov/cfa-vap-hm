# Extra command-line tools; an extra toggled via modules/manifest.json
# (toggle with `hmt` / tui.py).
{ ... }:
{
  programs = {
    lazygit.enable = true;
    nushell.enable = true;
  };
}
