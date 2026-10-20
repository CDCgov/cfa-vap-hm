# oh-my-zsh theming + plugins for zsh (configured further in home.nix);
# an extra toggled via modules/manifest.json (toggle with `hmt`).
{ ... }:
{
  programs.zsh.oh-my-zsh = {
    enable = true;
    plugins = [
      "azure"
      "docker"
      "gh"
      "git"
      "podman"
    ];
    theme = "lambda";
  };
}
