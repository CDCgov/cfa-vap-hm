# SQL tooling; an extra toggled via modules/manifest.json
# (toggle with `hmt` / tui.py). Off by default to save space.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    dbeaver-bin # cross-platform GUI database client
    postgresql # provides psql
    duckdb # in-process SQL OLAP database
  ];
}
