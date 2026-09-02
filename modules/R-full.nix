# Full R install
# Includes many packages out of the box and Rstudio
# You can still install packages manually
{ pkgs, ... }:
let
  # Shared package list used by both the RStudio wrapper and the
  # command-line R wrapper so they stay in sync.
  rPackageList = with pkgs.rPackages; [
    # analytics
    data_table
    rpart
    stringi
    stringr
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

  # R packages
  home.packages = with pkgs; [
    # rstudioWrapper.override gives you RStudio with the packages
    # available *inside* RStudio.
    (rstudioWrapper.override {
      packages = rPackageList;
    })
    # rWrapper.override gives you a command-line `R` / `Rscript` on your
    # PATH (visible to `which R`) with the same packages available.
    (rWrapper.override {
      packages = rPackageList;
    })
  ];
}
