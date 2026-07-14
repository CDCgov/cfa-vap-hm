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

  # Work around an upstream nixpkgs bug in rstudio-2026.04.0+526: the
  # preConfigure phase symlinks every hunspell dictionary with `ln -s`
  # (no -f). The dictionary list ships two ru-RU dictionaries that both
  # provide ru_RU.aff/ru_RU.dic, so the second symlink collides and the
  # build fails with "ln: failed to create symbolic link ... File exists".
  # Switching to `ln -sf` makes the linking idempotent.
  rstudioFixed = pkgs-unstable.rstudio.overrideAttrs (old: {
    preConfigure = builtins.replaceStrings
      [ "ln -s $i dependencies/dictionaries/" ]
      [ "ln -sf $i dependencies/dictionaries/" ]
      old.preConfigure;
  });
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
    # rstudioWrapper gives RStudio using the same R and package set,
    # built from the patched rstudio that fixes the dictionary symlink clash.
    (rstudioWrapper.override {
      packages = rPkgs;
      rstudio = rstudioFixed;
    })
  ];
}