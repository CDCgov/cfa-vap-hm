# The "full" profile - everything in home.nix beyond the core essentials.
# Selected by modules/state.json (toggle with `hmt` / utils/module_tui.py).
{ lib, pkgs, ... }:
{
  programs = {

    lazygit.enable = true;
    nushell.enable = true;
    uv.enable = true; # uv python manager

    # oh-my-zsh: theming + plugin manager for zsh (configured in home.nix)
    zsh.oh-my-zsh = {
      enable = true;
      plugins = [
        "azure"
        "docker"
        "gh"
        "git"
        "podman"
      ];
      theme = "lambda";
    };

  };

  home.packages = with pkgs; [

    # GUI apps and IDEs
    emacs
    neovim-unwrapped
    codex
    opencode

    # Dev/languages
    cargo
    gcc # includes gcc and g++
    gnumake
    pkg-config # discovers library compiler and linker flags
    nodejs

    # Native libraries and development headers (Ubuntu's lib*-dev equivalents).
    # Nix splits headers/pkg-config metadata into separate development outputs.
    # This replicates:
    # https://potential-adventure-637em36.pages.github.io/guides/vscode_for_r.html?h=languageserver#configure-vscode-for-r-development
    curl
    (lib.getDev curl)
    openssl
    (lib.getDev openssl)
    libxml2
    (lib.getDev libxml2)
    fontconfig
    (lib.getDev fontconfig)
    cairo
    (lib.getDev cairo)

  ];
}
