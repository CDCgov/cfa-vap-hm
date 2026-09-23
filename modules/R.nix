# R packages defined here; this is for clarity, not technical necessity
# i.e. we could've defined them in home.nix just the same
{ pkgs, ... }:
let
  # Package list used by the command-line R wrapper.
  rPackageList = with pkgs.rPackages; [
    # package management
    pak
    renv
    # utilities
    devtools
    ggplot2
    jsonlite
    languageserver
    Rcpp
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