# CFA VAP Home Manager

A usable CFA-tailored config for [Nix home-manager](https://github.com/nix-community/home-manager).  
- Simply clone and run this repository to setup your VAP.
- You can run it at any point and undo it at any point.

## Principles
Nix and `home-manager` are declaratively reproducible rather than imperative. 
We might say something like "nix home-manager provides a virtual-environment for your whole user-space, rather than just a single programming language."
- You tell `home-manager` that you want R, python, and the Github CLI as an end result rather than that they should install R, python, and the Github CLI. 
- Under the hood, `nix` has a sophisticated way of installing exactly what's needed and how to reconcile your installed versions exactly as specified.

> [!TIP]
> To see what software are currently included, take a look at the `programs` and `pkgs` defined in [home.nix](./home.nix).  
> Think something should be added, updated, removed, or modified? Let us know in a [PR](https://github.com/CDCgov/cfa-vap-hm/pulls).

## Goals
To improve upon [CFA VAP Autoconfig](https://github.com/cdcent/cfa-vap) with the following principles in mind:

- Simplicity, in terms of maintenance and installation
- Extensibility and customization
- [Declarative reproducibility](https://en.wikipedia.org/wiki/Declarative_programming)
- Platform agnosticisty

## Installation

> [!CAUTION]
> CFA VAP Home Manager is currently in early development - updates may break things.
> You might want to try [prototyping with docker](#prototyping-with-docker) before committing to installation.
> Also note that we use [determinate Nix](https://github.com/DeterminateSystems/nix-installer) to get flakes and run commands out of the box.

1. Clone this repository (or move your existing instance from before) to `~/.config/home-manager`.
    - `git clone https://github.com/cdcgov/cfa-vap-hm ~/.config/home-manager`.
1. Install `nix` on your machine using the [Determinate](https://determinate.systems/products/nix/) installer (recommended):
    - `curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm`.
    - If you're on WSL, using a container, or do not have `systemd` on your machine, see below for an alternative.
1. Install `home-manager` from our included flake and start your first home-manager generation:
    - Run `nix run ~/.config/home-manager -- switch --impure`.
    - `nix run . --impure`

### Installing for non-`systemd` environments
> [!NOTE]
> You'll need systemd enabled for to use the determinate installer (recommended).  
> If you don't have systemd, use upstream nix daemonless:
> 1. `sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon`
> 1. `echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf`
> 1. Add to your shell profile: `PATH=$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH`

### Uninstalling
Want to uninstall home-manager and everything you've done with it seamlessly?
- `home-manager uninstall`
- All programs and config you've setup with `home-manager` will be removed instantly.

## Development and Customization

### Prototyping with docker

> Make sure you have `docker` installed and enabled before running the following steps.

Before committing to having your system managed with nix, you can test the config in this repository with docker to see what it will do.
To do so, first clone this repository and set it as your working directory.

From the repo root: 
- `docker build -t vap-hm . && docker run -it --rm -v "$PWD/home.nix:/home/vapuser/.config/home-manager/home.nix" vap-hm` 
    - This builds and jumps into a development docker container with `home-manager` installed and initialized, using `flake.nix` and `home.nix` defined here.
    - This allows you to have a fully fresh session each time without modifying your existing system just yet.

While prototyping inside docker (you can also do this after installing outside docker):
1. Try any normal development commands (e.g., `uv run`, `Rscript`, etc.) and see what works, or what doesn't.
1. Modify `home.nix` as you like.
1. Run `home-manager switch --impure` to activate your new changes. That's it!
    - On `zsh`, you can also run `hms` from anywhere.

You can always repeat the low-risk [prototyping](#prototyping-with-docker) process before committing your own changes as an added layer of assurance.
- Nix also has a concept called "generations" that lets you roll back to any previous config - it's like git but for your whole system.
- See: https://nix-community.github.io/home-manager/#sec-usage-rollbacks

### Submitting your own changes as PRs
1. Open a new branch in your local `.config/home-manager` repository.
2. Make changes, commit, and push your branch. Test in docker or on your system first.
3. Open a PR!

## Helpful links:
> See the official docs:
> - https://nix-community.github.io/home-manager/
> - https://github.com/nix-community/home-manager

> With thanks to:
> - https://zenoix.com/posts/get-started-with-nix-and-home-manager/#what-is-home-manager
> - https://www.chrisportela.com/posts/home-manager-flake/
