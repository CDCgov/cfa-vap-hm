{ pkgs-unstable, ... }:
let
  # Shared R package set, used by both R (rWrapper) and RStudio (rstudioWrapper)
  rPkgs = with pkgs-unstable.rPackages; [
    # analytics
    data_table
    rpart
    tidyverse
    # package management
    pak
    renv
    # utilities
    cowplot
    devtools
    ggplot2
    jsonlite
    languageserver
    lintr
    Rcpp
    readxl
    styler
    yaml
  ];
in
{
  # home directory dotfiles
  home.file.".Rprofile".source = ../dotfiles/.Rprofile;

  # R packages (built from nixpkgs unstable to get R 4.6)
  home.packages = with pkgs-unstable; [
    # rWrapper.override gives you r itself,
    # then the packages block gives you individual packages
    (rWrapper.override {
      packages = rPkgs;
    })
    # rstudioWrapper gives RStudio using the same R and package set
    (rstudioWrapper.override {
      packages = rPkgs;
    })
  ];
}