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
      tui = import ./tui.nix { inherit pkgs; };
    in
    {
      packages.${system} = {
        inherit tui;
        # Use --tui to select tools; otherwise forward to Home Manager.
        default = pkgs.writeShellApplication {
          name = "cfa-vap-hm";
          text = ''
            if [[ "''${1:-}" == "--tui" ]]; then
              shift
              if [[ -z "''${HM_DIR:-}" && -f "$PWD/modules/manifest.json" ]]; then
                export HM_DIR="$PWD"
              fi
              exec ${tui}/bin/cfa-vap-tui "$@"
            fi
            exec ${home-manager.packages.${system}.home-manager}/bin/home-manager "$@"
          '';
        };
      };

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
              # selection.nix imports the optional modules selected in
              # modules/state.json (manifest.json lists what may be
              # selected; toggle with `hmt`)
              ./modules/selection.nix
            ];
            extraSpecialArgs = {
              inherit user homedir release;
            };
          };
        };
    };
}
