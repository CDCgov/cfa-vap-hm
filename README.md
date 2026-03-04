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

## Rapid low-risk prototyping
> Make sure you have docker installed and enabled before running the following steps.  

First, clone this repository and `cd` into it.

Then you can iteratively:
1. Modify `home.nix`. (Optional) 
    - You can try adding new packages, etc. 
    - There are lots of examples of things you can do with `home.nix` on github and elsewhere.
2. `make run` 
    - This builds and jumps into a development docker container with `home-manager` installed and initialized, using `flake.nix` and `home.nix` defined here.
    - This allows you to have a fully fresh session each time without modifying your existing system just yet.
3. Try any normal development commands (e.g., `uv run`, `Rscript`, etc.) and see what works, or what doesn't!

## Installation instructions
Once you're satisfied with prototyping, you can try installing and initializing `home-manager` for real. 

1. Clone into this repository (or move your existing version from before) to `~/.config/home-manager` and `cd` into it.
2. Install `nix` on your machine and enable the flakes feature:
    1. Run `sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon` to install `nix`.
        - Use `--no-daemon` instead if you are running nix inside a container or if you want to keep it limited to your user.
        - For details, see: https://nixos.org/download/#nix-install-linux.
    2. Run `echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf` to enable flakes and the `nix run` command.
3. Install `home-manager` and initialize based on the flake in this repository: 
    1. Run `nix run home-manager -- init --switch --flake ~/.config/home-manager --impure`
        - This will initialize the `home-manager` config you cloned in step 1 and also activate it.

If you have a new configuration you'd like to try, you can customize your own `home.nix` and even submit PRs to `main`:

## Making new changes to your installed version of home-manager

### Customizing your own config
1. Make changes to `~/.config/home-manager/home.nix`. For example, you might add to the packages list.
2. Run `home-manager switch --flake ~/.config/home-manager --impure` to activate your new changes. That's it!

You can always repeat the "Rapid Low-risk Prototyping" process before committing your own changes as an added layer of assurance.
- Nix also has a concept called "generations" that lets you roll back to any previous config - it's like git but for your whole system.  
- See: https://nix-community.github.io/home-manager/#sec-usage-rollbacks


### Submitting your own changes as PRs
1. Open a new branch in your `.config/home-manager` repository.
2. Make changes and push your branch.
3. Open a PR.

