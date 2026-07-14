{ pkgs-unstable, ... }:
{
  # home directory dotfiles
  home.file.".Rprofile".source = ../dotfiles/.Rprofile;

  # R packages (built from nixpkgs unstable to get R 4.6)
  home.packages = with pkgs-unstable; [
    # rWrapper.override gives you r itself,
    # then the with rPackages block gives you
    # individual packages
    (rWrapper.override {
      packages = with rPackages; [
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
    })
  ];
}