{
  description = "CFA VAP Home Manager configurations";
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
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = builtins.currentSystem;
      pkgs = nixpkgs.legacyPackages.${system};
      user = builtins.getEnv "USER";
      homedir = builtins.getEnv "HOME";
      release = "26.05";
      mkHome = { modules, profileName }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs modules;
          extraSpecialArgs = {
            inherit user homedir release profileName;
          };
        };
    in
    {
      homeConfigurations = {
        # Lite R profile
          ${user} = mkHome {
            profileName = "base";
            modules = [
              ./home.nix
              ./modules/R/lite.nix
            ];
          };

          # Base profile + R tooling
          "${user}-r" = mkHome {
            profileName = "R-full-install";
            modules = [
              ./home.nix
              ./modules/R/full.nix
            ];
          };
      };
    };
}
