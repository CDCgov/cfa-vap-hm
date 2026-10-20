# Visual Studio Code; an extra toggled via modules/manifest.json
# (toggle with `hmt` / utils/module_tui.py). Off by default to save space.
# Installed as a plain package rather than programs.vscode so home-manager
# does not take over the user's VS Code settings.
{ pkgs, ... }:
{
  home.packages = [ pkgs.vscode ];
}
