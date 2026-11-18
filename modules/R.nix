# R packages defined here; this is for clarity, not technical necessity
# i.e. we could've defined them in home.nix just the same
{ config, ... }:
let
  # Pin R to a specific version via nixpkgs-multiverse. We resolve the full
  # nixpkgs revision for that R version so `rWrapper` and `rPackages` are built
  # against the exact same R release.
  mv = config.multiverse.instance;
  rVersion = "4.5.3";
  rPkgs = mv.at (mv.revOf "R" rVersion);

  # Package list used by the command-line R wrapper.
  rPackageList = with rPkgs.rPackages; [
    # package management
    pak
    # utilities
    languageserver
  ];
in
{
  # home directory dotfiles
  home.file.".Rprofile".source = ../dotfiles/.Rprofile;

  # R packages
  home.packages = [
    # rWrapper.override gives you a command-line `R` / `Rscript` on your
    # PATH (visible to `which R`) with the same packages available.
    (rPkgs.rWrapper.override {
      packages = rPackageList;
    })
  ];
}
