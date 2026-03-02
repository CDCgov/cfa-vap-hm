{
    # Flakes are declarative config files that specify dev environments
    description = "Jon's Experimental Home-Manager Flake";

    # "Inputs = ..."" 
    # This is our basic dependency information - we're just including home-manager here
    # and letting the home.nix file do the rest!
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    # "Outputs = ..." - what are we producing with the previously defined inputs?
    
    # This is where we tell nix to create a home-manager configuration for our username,
    # and we're going to define all further program/dotfile information in ./home.nix
    outputs = {nixpkgs, home-manager, ...}: {
        homeConfigurations = {
            "qxk3" = home-manager.lib.homeManagerConfiguration {
                # System is very important!
                pkgs = import nixpkgs { system = "x86_64-linux"; };
                modules = [ ./home.nix ]; # Defined later
            };
        };
    };
}