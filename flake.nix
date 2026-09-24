{
  description = "CFA VAP Home Manager configuration";
  inputs = {
    # Specify the sources of Nixpkgs and Home Manager .
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-26.05";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      # Explicit target platform; builtins.currentSystem is unavailable in pure evaluation.
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Let `nix run . --impure` launch this flake's Home Manager CLI.
      packages.${system}.default = home-manager.packages.${system}.home-manager;

      homeConfigurations =
        let
          user = builtins.getEnv "USER";
          homedir = builtins.getEnv "HOME";
          release = "26.05";
        in
        {
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
    };
}
