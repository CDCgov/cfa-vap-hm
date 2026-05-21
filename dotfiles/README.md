# Dotfiles for CFA VAP Home Manager

Files you put in `$HOME` to configure shells, etc.

## Instructions

To add a dotfile:
1. Add it to this directory (`dotfiles/`), as is.
2. Add a line to home.nix: `home.file."<name_of_dotfile>".source = dotfiles/<name_of_dotfile>;`
3. Run `home-manager switch --flake . --impure` (or `make switch`).

## Notes on shell dotfiles (.profile, .zshrc, etc.)
1. Currently, `cfa-vap-hm` configures `zsh` with `oh-my-zsh` under the hood, including its dotfiles.
2. `home.nix` creates a `.vaprc` if you don't have one, and then sources it. Use this for personal configuration untracked by `home-manager`. Think of this as just adding additional custom lines to your `.zshrc`. If you think something is worth including for everyone, feel free to submit a PR changing the `zsh` `initConent` block in `home.nix`!
3. You should not modify the version of the dotfiles at `$HOME`(`~`) like you may be used to doing. These are read-only.
   - Instead, modify the version controlled versions in `~/.config/home-manager` and then run `make switch`.
