# Nix Home Manager Config for use with CFA VAP
> With thanks to https://www.chrisportela.com/posts/home-manager-flake/
> See: https://nix-community.github.io/home-manager/

This is an extremely experimental nix home manager setup for the CFA VAP (you can also try it on WSL on your GFE. There are ways to get it running on Mac OS, too, though some changes are needed.)

Nix home manager allows us to reproducibly maintain the same environments for all users across all platforms (WSL, Linux, and Mac) and also allows users their own customizability and ability to suggest changes to our upstream version.

This is currently an extremely experimental and minimal example. Use at your own risk for now!

## Installation instructions
1. Install nix for [Linux](https://nixos.org/download/#nix-install-linux) or for [Linux in WSL](https://nixos.org/download/#nix-install-windows).
2. Clone this repository to `~/.config/nix-home-manager`.
3. Run `nix home-manager init ~/.config/nix-home-manager`.

## Customizing your own config
1. Ideally, fork the repository to your own user in Github, and either initially clone from there or add this new fork as a remote with `git remote add fork <your url>`.
2. Make changes to `home.nix`.
3. Commit your changes and push them to github (on your fork).
4. `nix-home-manager switch ~/.config/nix-home-manager`.

Also feel free to submit PRs to our larger CFA VAP nix-home-manager config.