{
  description = "CFA VAP Home Manager configuration";
  inputs = {
    # Specify the sources of Nixpkgs and Home Manager .
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-25.11";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kickstart.url = "github:nvim-lua/kickstart.nvim";
    kickstart.flake = false;
  }; 

  outputs = { nixpkgs, home-manager, kickstart, ... }:
    let
      system = builtins.currentSystem;
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations = let
        user = builtins.getEnv "USER";
        homedir = builtins.getEnv "HOME";
        release = "25.11";
      in {
        ${user} = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ 
            ./home.nix 
          ];
          extraSpecialArgs = {
            inherit user homedir release kickstart;
          };
        };
      };
    };
}