# Lite R install - lacks most packages and does not include Rstudio.
# You can still install packages manually.
{ pkgs, ... }:
let
  # Package list used by the command-line R wrapper.
  rPackageList = with pkgs.rPackages; [
    # package management
    pak
    renv
    # utilities
    devtools
    languageserver
  ];
in
{
  # home directory dotfiles
  home.file.".Rprofile".source = ../dotfiles/.Rprofile;

  # R packages
  home.packages = with pkgs; [
    # rWrapper.override gives you a command-line `R` / `Rscript` on your
    # PATH (visible to `which R`) with the same packages available.
    (rWrapper.override {
      packages = rPackageList;
    })
  ];
}
