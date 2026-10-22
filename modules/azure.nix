# Azure tooling; a member of the "extras" group declared in
# modules/manifest.json (toggle with `hmt` / tui.py).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    azure-cli
    azure-storage-azcopy
    blobfuse
  ];

  programs.zsh.shellAliases = {
    bf = "azure-storage-fuse"; # nix's blobfuse is created as azure-storage-fuse
  };
}
