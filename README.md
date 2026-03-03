# Nix Home Manager for the CFA VAP
> With thanks to: 
> - https://zenoix.com/posts/get-started-with-nix-and-home-manager/#what-is-home-manager
> - https://www.chrisportela.com/posts/home-manager-flake/

> See: 
> - https://nix-community.github.io/home-manager/
> - https://github.com/nix-community/home-manager

This is an extremely experimental nix home manager setup for the CFA VAP (you can also try it on WSL on your GFE. There are ways to get it running on Mac OS, too, though some changes are needed.)

Nix home manager allows us to reproducibly maintain the same environments for all users across all platforms (WSL, Linux, and Mac) and also allows users their own customizability and ability to suggest changes to our upstream version.

This is currently an extremely experimental and minimal example. Use at your own risk for now!

## Installation instructions
1. Clone this repository as `~/.config/home-manager`.
    - gh cli: `gh repo clone jkislin/nix-home-manager ~/.config/home-manager`
    - git cli: `git clone https://github.com/jkislin/nix-home-manager.git ~/.config/home-manager`

2. Install `nix`:
    - `sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon`
    - For details, see: https://nixos.org/download/#nix-install-linux.

3. Install `home-manager` and initialize: 
    - `nix run github:nix-community/home-manager -- init --switch`
    - This will initialize the `home-manager` config you cloned in step 1 and also activate it.

## Customizing your own config
1. Make changes to `~/.config/home-manager/home.nix`.
2. Run `home-manager switch` to activate your new changes. That's it!

## Submitting your own changes as PRs
1. Open a new branch in your `.config/home-manager` repository.
2. Make changes and push your branch.
3. Open a PR.