# CFA VAP Home Manager

This repository contains a usable config for [Nix home-manager](https://github.com/nix-community/home-manager) - a tool that allows one to reproduce entire computing environments across unix-like platforms (WSL, Linux, and Mac) and is intended to grow into a solution we can use on the VAP. It's declarative, which means you tell it what you want the end result to be, rather than what it should do (imperative).

For example, instead of writing a script that installs R, python, and the Github CLI, we provide a functional configuration file that declares that the system should, as an end result, include R, python, and the Github CLI. The nix package manager then takes it from there. We might say something like "nix home-manager provides a virtual-environment for your whole user-space, rather than just a single programming language."

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

Once you're satisfied with prototyping, you can try installing and initializing `home-manager` for real. 

1. Clone this repository (or move your existing instance from before) to `~/.config/home-manager`.
2. Install `nix` on your machine:
    - `sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon`.
        - Use `--no-daemon` instead if you are running nix inside a container or if you want to keep it limited to your user.
        - For details, see: https://nixos.org/download/#nix-install-linux.
3. Enable the `nix run` subcommand and "flakes" feature:
    1. First, run `mkdir -p ~/.config/nix/` to create the nix config directory.
    2. Then, run `echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf`.
4. Install `home-manager` and initialize based on the flake in this repository: 
    - Run `nix run home-manager -- init --switch --flake ~/.config/home-manager --impure`.

## Development and Customization

### Prototyping with docker

> Make sure you have both `docker` and `make` installed and enabled before running the following steps.  

Before committing to having your system managed with nix, you can test the config in this repository with docker to see what it will do.
To do so, first clone this repository and set it as your working directory.

Then you can iteratively:
1. Modify `home.nix`. (Optional) 
    - You can try adding new packages, etc. 
    - There are lots of examples of things you can do with `home.nix` on github and elsewhere.
2. `make test` 
    - This builds and jumps into a development docker container with `home-manager` installed and initialized, using `flake.nix` and `home.nix` defined here.
    - If you don't like Makefiles, you can run `docker build -t vap-hm . && docker run -it --rm vap-hm bash` instead. It does the same thing.
    - This allows you to have a fully fresh session each time without modifying your existing system just yet.
3. Try any normal development commands (e.g., `uv run`, `Rscript`, etc.) and see what works, or what doesn't!

### Customizing your own config
1. Open up an IDE using `~/.config/home-manager` as the working directory.
2. Make changes to `~/.config/home-manager/home.nix`. For example, you might add to the programs or packages list, or propose a different configuration of an existing program.
3. Run `home-manager switch --impure` to activate your new changes. That's it!
    - For convenience, you can run `make switch` if you're in the top level of this repository.

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

## Legacy Imperative Scripts
> See [the legacy scripts README](./scripts/README.md) for more information.

Run `bash ./scripts/setup-fstab.sh` to mount network drives. Note this may be deprecated and is not part of home-manager, but is included in this repository for convenience. This script can only be run within a Linux or WSL environment on the CFA VAP - it will not work outside of it.