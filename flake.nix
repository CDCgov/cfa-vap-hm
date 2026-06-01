{
  description = "CFA VAP Home Manager configuration";
  inputs = {
    # Specify the sources of Nixpkgs and Home Manager .
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # List any source urls for packages not on nixpkgs here
    lazyvim.url = "github:pfassina/lazyvim-nix";
  }; 

  outputs = { nixpkgs, home-manager, lazyvim, ... }:
    let
      system = builtins.currentSystem;
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations = let
        user = builtins.getEnv "USER";
        homedir = builtins.getEnv "HOME";
        release = "26.05";
      in {
        ${user} = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ 
            ./home.nix 
          ];
          extraSpecialArgs = {
            inherit user homedir release lazyvim;
          };
        };
      };
    };
}