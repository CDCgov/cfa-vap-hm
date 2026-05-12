# Dotfiles for CFA VAP Home Manager

Files you put in `$HOME` to configure shells, etc.

## Instructions

To add a dotfile:
1. Add it to this directory (`dotfiles/`), as is.
2. Add a line to home.nix: `home.file."<name_of_dotfile>".source = dotfiles/<name_of_dotfile>;`
3. Run `home-manager switch --flake . --impure` (or `make switch`).