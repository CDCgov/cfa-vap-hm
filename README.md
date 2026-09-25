# CFA VAP Home Manager

This repository contains a usable config for [Nix home-manager](https://github.com/nix-community/home-manager) - a tool that allows one to reproduce an entire user-space across unix-like platforms (WSL, Linux, and Mac) and is intended to grow into a solution we can use on the VAP. It's declarative, which means you tell it what you want the end result to be, rather than what it should do (imperative).

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
> Also note that we use [determinate Nix](https://github.com/DeterminateSystems/nix-installer) to get flakes and run commands out of the box.

Once you're satisfied with prototyping, you can try installing and initializing `home-manager` for real.

1. Clone this repository (or move your existing instance from before) to `~/.config/home-manager`.
2. Install `nix` on your machine:
    - `curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm`.
    - Note that you'll need systemd enabled for this.
3. Install `home-manager` from our included flake and start your first home-manager generation:
    - Run `nix run ~/.config/home-manager -- switch --impure`. (`nix run . -- switch --impure` if you're in the directory)

## Development and Customization

### Prototyping with docker

> Make sure you have `docker` installed and enabled before running the following steps.

Before committing to having your system managed with nix, you can test the config in this repository with docker to see what it will do.
To do so, first clone this repository and set it as your working directory.

Then you can iteratively:
1. Modify `home.nix`. (Optional)
    - You can try adding new packages, etc.
    - There are lots of examples of things yous can do with `home.nix` on github and elsewhere.
2. `docker build . -t vap-hm && docker run -it --rm vap-hm`
    - This builds and jumps into a development docker container with `home-manager` installed and initialized, using `flake.nix` and `home.nix` defined here.
    - This allows you to have a fully fresh session each time without modifying your existing system just yet.
3. Try any normal development commands (e.g., `uv run`, `Rscript`, etc.) and see what works, or what doesn't!

### Customizing your own config
1. Open up an IDE using `~/.config/home-manager` as the working directory.
2. Make changes to `~/.config/home-manager/home.nix`. For example, you might add to the programs or packages list, or propose a different configuration of an existing program.
3. Run `home-manager switch --impure` to activate your new changes. That's it!
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
