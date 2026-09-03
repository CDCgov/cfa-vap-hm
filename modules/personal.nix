# Personal .nix
# Modify this alone for your personal config

# If you believe cfa predict as a whole should have a config,
# submit a pr targeting upstream home.nix!

{ pkgs, ... }:
{
  nixpkgs.config = {
    allowUnfree = true;
  };
  home.packages = with pkgs; [
    # Add additional packages here, newline delimited
  ];
}
