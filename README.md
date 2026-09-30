# CFA VAP Home Manager

A usable CFA-tailored config for [Nix home-manager](https://github.com/nix-community/home-manager).
- Simply clone and run this repository to setup your VAP.
- You can run it at any point and undo it at any point.

> [!TIP]
> To see what software are currently included, take a look at the `programs` and `pkgs` defined in [home.nix](./home.nix).  
> Think something should be added, updated, removed, or modified? Let us know in a [PR](https://github.com/CDCgov/cfa-vap-hm/pulls).

## Principles
Nix and `home-manager` are declarative rather than imperative.
- This means you declare what setup your system should have, not what it should do to get there.
- If you're familiar with `uv` for python:
    - Nix uses `flake.nix` (akin to `pyproject.toml`) and `flake.lock` (akin to `uv.lock`) to maintain reproducibility.
- You might think of Nix (and `home-manager` by extension) as a virtual environment manager for your whole user-space.

## Project Goals

To provide an automated, repeatable, and maintainable way to configure every CFA VAP user's development environment.  

 `cfa-vap-hm` improves on our previous solution, [CFA VAP Autoconfig](https://github.com/cdcent/cfa-vap), by being:

- simpler, in terms of maintenance and installation
- more customizable
- [declaratively reproducible](https://en.wikipedia.org/wiki/Declarative_programming)
- (somewhat) platform agnostic


## Installation

> [!TIP]
> Uninstalling `home-manager` (and reverting anything you've done with it) is as simple as running `home-manager uninstall`.  
> - However, if you want to try it in a sandbox first, see: [prototyping with docker](#prototyping-with-docker).

To install `cfa-vap-hm`, simply:
1. Clone this repository (or move your existing instance from before) to `~/.config/home-manager`.
    - `git clone https://github.com/cdcgov/cfa-vap-hm ~/.config/home-manager`.
1. Install `nix` on your machine using the [Determinate](https://determinate.systems/products/nix/) installer (recommended):
    - `curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm`.
    - If you're on WSL, using a container, or do not have `systemd` on your machine, see below for an alternative.
1. Install `home-manager` from our included flake and start your first `home-manager` generation:
    - Run `nix run ~/.config/home-manager -- switch --impure`.

### Installing for non-`systemd` environments
> [!NOTE]
> You'll need systemd enabled for to use the determinate installer (recommended).  
> If you don't have systemd, use upstream nix daemonless:  
> 1. `sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon`
> 1. `echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf`
> 1. Add to your shell profile: `PATH=$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH`

### Uninstalling
- If you run `home-manager uninstall`, all programs and config you've setup with `home-manager` will be removed instantly.
- You can reinstall simply by running `nix run ~/.config/home-manager -- switch --impure` again.

## Development and Customization

### Prototyping with docker

> Make sure you have `docker` installed and enabled before running the following steps.

Before committing to managing your environment with nix, you can test the changes with docker.  
To do so, first clone this repository and set it as your working directory.

From the repo root:
- `docker build -t vap-hm . && docker run -it --rm -v "$PWD/home.nix:/home/vapuser/.config/home-manager/home.nix" vap-hm`
    - This builds and jumps into a development docker container with `home-manager` installed and initialized, using `flake.nix` and `home.nix` defined here.
    - This allows you to have a fully fresh session each time without modifying your existing system just yet.

### Customizing your config

After you install `home-manager`, or while prototyping with docker:

1. Try any normal development commands (e.g., `uv run`, `Rscript`, etc.) and see what works, or what doesn't.
1. Modify `home.nix` as you like.
1. Run `home-manager switch --impure` to activate your new changes. That's it!
    - Note that you'll need to keep your `home-manager` `flake.nix` in `~/.config/home-manager` for this to work correctly.
    - On `zsh`, you can also run `hms` from anywhere.

You can always repeat the low-risk [prototyping](#prototyping-with-docker) process before committing your own changes as an added layer of assurance.
- Nix also has a concept called "generations" that lets you roll back to any previous config - it's like git but for your whole system.
- See: https://nix-community.github.io/home-manager/#sec-usage-rollbacks

### Submitting your own changes as PRs
1. Open a new branch in your local `.config/home-manager` repository.
2. Make changes, commit, and push your branch. Test in docker or on your system first.
3. Open a PR!

If you want to make a config tailored to your own use-cases but don't think it's useful for the entire organization, please make a fork!

## Helpful links:
> See the official docs:
> - https://nix-community.github.io/home-manager/
> - https://github.com/nix-community/home-manager

> With thanks to:
> - https://zenoix.com/posts/get-started-with-nix-and-home-manager/#what-is-home-manager
> - https://www.chrisportela.com/posts/home-manager-flake/
> - [Gio's home-manager config](https://github.com/giomrella/nix-home-manager)

## Utility Scripts
We include some utility scripts outside of the `home-manager` ecosystem for convenience.
- See [utils/](./utils/)

## Disclaimers

### General Disclaimer

This repository was created for use by CDC programs to collaborate on public health related projects in support of the [CDC mission](https://www.cdc.gov/about/cdc/index.html).
GitHub is not hosted by the CDC, but is a third party website used by CDC and its partners to share information and collaborate on software.
CDC use of GitHub does not imply an endorsement of any one particular service, product, or enterprise.

### Public Domain Standard Notice

This repository constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105.
This repository is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
All contributions to this repository will be released under the CC0 dedication.
By submitting a pull request you are agreeing to comply with this waiver of copyright interest.

### License Standard Notice

This repository is licensed under Apache-2.0 or later.

This source code in this repository is free: you can redistribute it and/or modify it under the terms of the Apache License, Version 2.0, or (at your option) any later version.

This source code in this repository is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the Apache Software License for more details.

You should have received a copy of the Apache Software License along with this program.
If not, see http://www.apache.org/licenses/LICENSE-2.0.html

The source code forked from other open source projects will inherit its license.

### Privacy Standard Notice

This repository contains only non-sensitive, publicly available data and information.
All material and community participation is covered by the [Disclaimer](https://github.com/CDCgov/template/blob/master/DISCLAIMER.md) and [Code of Conduct](https://github.com/CDCgov/template/blob/master/code-of-conduct.md).
For more information about CDC's privacy policy, please visit <https://www.cdc.gov/other/privacy.html>.

### Contributing Standard Notice

Anyone is encouraged to contribute to the repository by [forking](https://help.github.com/articles/fork-a-repo) and submitting a pull request.
(If you are new to GitHub, you might start with a [basic tutorial](https://help.github.com/articles/set-up-git).)
By contributing to this project, you grant a world-wide, royalty-free, perpetual, irrevocable, non-exclusive, transferable license to all users under the terms of the [Apache Software License v2](http://www.apache.org/licenses/LICENSE-2.0.html) or later.

All comments, messages, pull requests, and other submissions received through CDC including this GitHub page may be subject to applicable federal law, including but not limited to the Federal Records Act, and may be archived.
Learn more at <http://www.cdc.gov/other/privacy.html>.

### Records Management Standard Notice

This repository is not a source of government records but is a copy to increase collaboration and collaborative potential.
All government records will be published through the [CDC web site](http://www.cdc.gov).
