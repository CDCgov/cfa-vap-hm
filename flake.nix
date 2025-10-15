{
  description = "Home Manager configuration of gio";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations = (builtins.listToAttrs (
        map
          (user: {
            name = user;
            value = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [ ./home.nix ];
              extraSpecialArgs = {
                inherit user;
                # remove domain e.g. ap82@ext.cdc.gov -> ap82
                homedir = builtins.elemAt (builtins.split "@" user) 0;
              };
            };
          })
          ["gio" "ap82@ext.cdc.gov"]
      ));
    };
}
