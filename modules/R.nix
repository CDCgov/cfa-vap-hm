{ pkgs, ... }:
{
  home.packages = with pkgs; [
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