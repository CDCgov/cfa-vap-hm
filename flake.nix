{
  description = "CFA VAP Home Manager configuration";
  inputs = {
    # Stable nixpkgs (26.05) provides the bulk of packages.
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-26.05";
    };
    # Unstable nixpkgs is used only for R (to get R 4.6).
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    home-manager = {
      # Track the release branch that matches the stable nixpkgs above.
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  }; 

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      system = builtins.currentSystem;
      # Stable package set (nixpkgs 26.05).
      pkgs = nixpkgs.legacyPackages.${system};
      # Unstable package set, used for R 4.6 in modules/R.nix.
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      homeConfigurations = let
        user = builtins.getEnv "USER";
        homedir = builtins.getEnv "HOME";
        release = "26.05";
      in {
        ${user} = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ 
            ./modules/home.nix
            ./modules/R.nix
          ];
          extraSpecialArgs = {
            inherit user homedir release pkgs-unstable;
          };
        };
      };
    };
}