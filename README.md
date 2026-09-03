# CFA VAP Home Manager

This repository contains a usable config for [Nix home-manager](https://github.com/nix-community/home-manager) - a tool that allows one to reproduce an entire user-space across unix-like platforms (WSL, Linux, and Mac) and is intended to grow into a solution we can use on the VAP. It's declarative, which means you tell it what you want the end result to be, rather than what it should do (imperative).

For example, instead of writing a script that installs R, python, and the Github CLI, we provide a functional configuration file that declares that the system should, as an end result, include R, python, and the Github CLI. The nix package manager then takes it from there. We might say something like "nix home-manager provides a virtual-environment for your whole user-space, rather than just a single programming language."

> [!TIP]
> To see what software are currently included, take a look at the `programs` and `pkgs` defined in [home.nix](./home.nix).
> Think something should be added, updated, removed, or modified? Let us know in a [PR](https://github.com/CDCgov/cfa-vap-hm/pulls).

> Note, we are also considering [numtide's nix system manager](https://github.com/numtide/system-manager) for inclusion here. This requires sudo.

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
1. Install `nix` on your machine:
    - `sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon`.
        - Use `--no-daemon` instead if you are running nix inside a container or if you want to keep it limited to your user.
        - For details, see: https://nixos.org/download/#nix-install-linux.
1. Enable the `nix run` subcommand and "flakes" feature:
    1. First, run `mkdir -p ~/.config/nix/` to create the nix config directory.
    2. Then, run `echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf`.
1. Install `home-manager` and initialize based on the flake in this repository:
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
1. `make test`
    - This builds and jumps into a development docker container with `home-manager` installed and initialized, using `flake.nix` and `home.nix` defined here.
    - If you don't like Makefiles, you can run `docker build -t vap-hm . && docker run -it --rm vap-hm bash` instead. It does the same thing.
    - This allows you to have a fully fresh session each time without modifying your existing system just yet.
1. Try any normal development commands (e.g., `uv run`, `Rscript`, etc.) and see what works, or what doesn't!

### Customizing your own config
1. Open up an IDE using `~/.config/home-manager` as the working directory.
1. Make changes to `~/.config/home-manager/personal.nix`. For example, you might add to the programs or packages list, or make a different configuration of an existing program.
1. Run `home-manager switch --impure` to activate your new changes. That's it!
    - For convenience, you can run `make switch` if you're in the top level of this repository.
    - On `zsh`, you can also run `hms` from anywhere if you've run `home-manager switch --impure` at least once before and sourced `~/.zshrc`.

> [!NOTE]
> By default, `home-manager switch` or `hms` will install a basic R installation (`./moudles/R/lite.nix`).
> run `hmsr` to get the packages in `./modules/R/full.nix`.

You can always repeat the low-risk [prototyping](#prototyping-with-docker) process before committing your own changes as an added layer of assurance.
- Nix also has a concept called "generations" that lets you roll back to any previous config - it's like git but for your whole system.
- See: https://nix-community.github.io/home-manager/#sec-usage-rollbacks

### Submitting changes as PRs
1. If you don't plan on customizing, and simply want to participate in development while using upstream `cfa-vap-hm`, just make a new branch on this repository.
    - Fork this repository to your own personal account first if you plan on using `personal.nix`.
1. Make changes, commit, and push your branch. Test to make sure it works. Note if you add any new modules, you'll have to commit before `home-manager switch` will work again.
1. Open a PR! Note that we will not accept changes to `personal.nix` files upstream unless they are for the template itself.

## Helpful links:
> See the official docs:
> - https://nix-community.github.io/home-manager/
> - https://github.com/nix-community/home-manager

> With thanks to:
> - https://zenoix.com/posts/get-started-with-nix-and-home-manager/#what-is-home-manager
> - https://www.chrisportela.com/posts/home-manager-flake/
