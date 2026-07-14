{ pkgs, ... }:
{
  # home directory dotfiles
  home.file.".Rprofile".source = ../dotfiles/.Rprofile;

  # R packages
  home.packages = with pkgs; [
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