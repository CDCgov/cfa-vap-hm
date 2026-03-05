# CFA VAP Home Manager

> [!CAUTION]
> CFA VAP Home Manager is a repository under active development.  
> You may experience bugs and updates may break things.

[Nix home-manager](https://github.com/nix-community/home-manager) is a tool that allows one to reproduce the same environments for all users across unix-like platforms (WSL, Linux, and Mac). It's declarative, which means you tell it what you want the end result to be, rather than what it should do (imperative).

For example, instead of writing a script that installs R, python, and the Github CLI, we provide a functional configuration file that declares that the system should, as an end result, include R, python, and the Github CLI. The nix package manager then takes it from there. We might say something like "nix home-manager provides a virtual-environment for your whole user-space, rather than just a single programming language."

### Goals:
1. Replace autoconfig with a new declarative and reproducible system we can easily maintain as a team.
2. Extend this functionality to the Linux VAP and to other computing environments.

As of current writing, this is currently an experimental and minimal example. Use at your own risk for now!

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

1. Clone this repository (or move your existing instance from before) to `~/.config/home-manager` and `cd` into it.
2. Install `nix` on your machine:
    1. Run `sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon` to install `nix`.
        - Use `--no-daemon` instead if you are running nix inside a container or if you want to keep it limited to your user.
        - For details, see: https://nixos.org/download/#nix-install-linux.
3. Enable the `nix run` subcommand and "flakes" feature:
    - `echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf`.
4. Install `home-manager` and initialize based on the flake in this repository: 
    1. Run `nix run home-manager -- init --switch --flake ~/.config/home-manager --impure`

## Customization and Contribution

### Customizing your own config
1. Make changes to `~/.config/home-manager/home.nix`. For example, you might add to the packages list.
2. Run `home-manager switch --flake ~/.config/home-manager --impure` to activate your new changes. That's it!

You can always repeat the ["Rapid Low-risk Prototyping"](#rapid-low-risk-prototyping) process before committing your own changes as an added layer of assurance.
- Nix also has a concept called "generations" that lets you roll back to any previous config - it's like git but for your whole system.  
- See: https://nix-community.github.io/home-manager/#sec-usage-rollbacks

## Helpful links:
> See the official docs: 
> - https://nix-community.github.io/home-manager/
> - https://github.com/nix-community/home-manager

> With thanks to: 
> - https://zenoix.com/posts/get-started-with-nix-and-home-manager/#what-is-home-manager
> - https://www.chrisportela.com/posts/home-manager-flake/


### Submitting your own changes as PRs
1. Open a new branch in your local `.config/home-manager` repository.
2. Make changes, commit, and push your branch.
3. Open a PR!

