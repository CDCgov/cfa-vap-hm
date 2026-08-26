{
  description = "Nix Home Manager and System Manager configurations for the CFA VAP";
  inputs = {
    # Specify the sources of Nixpkgs and Home Manager .
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-26.05";
    };
    # Home-manager source
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # System-manager source 
    system-manager = {
      url = "github:numtide/system-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # System Graphics acceleration source
    nix-system-graphics = {
      url = "github:soupglasses/nix-system-graphics";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, system-manager, nix-system-graphics, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      user = builtins.getEnv "USER";
      homedir = builtins.getEnv "HOME";
      release = "26.05";
    in
    {
      homeConfigurations = {
          ${user} = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./home.nix
              ./modules/R.nix
            ];
            extraSpecialArgs = {
              inherit user homedir release;
            };
          };
      };
      systemConfigs.default = system-manager.lib.makeSystemConfig {
        modules = [
          nix-system-graphics.systemModules.default
          {
            config = {
              nixpkgs.hostPlatform = system;
              system-manager.allowAnyDistro = true;
              system-graphics.enable = true;
            };
          }
        ];
      };
    };
}
