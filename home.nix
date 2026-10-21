# pkgs lets us access the nix store, which has tons of packages you'd want to get with apt etc.
{
  config,
  pkgs,
  user,
  homedir,
  release,
  lib,
  ...
}:
{

  nixpkgs.config = {
    allowUnfree = true;
  };
  # Username, homedirectory, and release are handled in flake.nix
  home.username = user;
  home.homeDirectory = homedir;
  home.stateVersion = release;
  home.activation.switchMessage = lib.hm.dag.entryAfter [ "WriteBoundary" ] ''
    ${pkgs.cowsay}/bin/cowsay -f dragon "CFA VAP Home Manager updated!" | ${pkgs.lolcat}/bin/lolcat
  '';

  # Programs and pkgs:

  # This file holds the *core* environment. Optional extras (editors, dev
  # toolchain, R, Azure, containers, ...) live in modules/ and are
  # selected by modules/state.json - toggle them with `hmt`.

  # Programs are preferrable to "pkgs" if they exist due to configurability;
  # However, there are far fewer software available as "programs"

  # All programs are pkgs under the hood, with additional config available

  # The only thing needed to install a program is to specify <program_name>.enable
  programs = {

    home-manager.enable = true;

    bat.enable = true; # rich cat
    git = {
      enable = true;
      settings = {
        init.defaultBranch = "main";
        pull.ff = "only";
      };
    };
    gh.enable = true; # github cli
    ripgrep.enable = true;
    tmux.enable = true;

    # fzf: fuzzy finder (Ctrl-R history, Ctrl-T files, Alt-C cd)
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    # zoxide: smarter `cd` (use `z <dir>`); its zsh integration adds the
    # shell hooks automatically.
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh = {
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
      shellAliases = {
        cb = "xclip -sel clipboard"; # pipe to this to add the command to the clipboard
        hms = "home-manager switch --flake ~/.config/home-manager/ --impure"; # switch from anywhere
        hmt = "python3 $HOME/.config/home-manager/tui.py"; # toggle home-manager modules (TUI)
      };
      initContent = ''
        echo "Welcome to the CFA VAP. You are using zsh as managed by nix home-manager." | lolcat
        echo "-> Now loading shell customizations you may have set in your ~/.vaprc config..." | lolcat
        # .vaprc is a personal rc file not managed by home-manager
        # add to your ~/.vaprc any commands/aliases/shell-config
        # you want for yourself alone.
        #
        # NOTE: This breaks the idea of pure declarative management - use at your own risk.

        touch ~/.vaprc
        source ~/.vaprc
      '';
    };

  };
  # Optional extras are declared in modules/ (editors, dev toolchain, R,
  # Azure, ...) and merged in by modules/selection.nix per modules/state.json.
  # Think of the list below as things you could install with apt on ubuntu.
  home.packages = with pkgs; [

    # Basics
    btop # system resource manager
    cowsay # a cow that says
    dysk # a better df (disk management)
    eza # fancy ls alternative
    fd # file finder
    figlet # ASCII-art banners (used by the `hmt` TUI title)
    git-filter-repo # remove sensitive data
    htop # legacy system resource manager
    jq # shell json parsing
    just
    lolcat # rainbow cats
    fastfetch # gives you system info
    tree # filesystem visualization
    xclip

    # Dev/languages (lint + repo tooling; the heavy toolchain is the `dev` extra)
    nixfmt
    pre-commit
    python313 # note that uv is also installed in 'programs'; also runs `hmt`
    ruff # python formatter
    shellcheck # tool that checks and lints shell scripts
    shfmt # formats shell scripts; complements shellcheck

    # Native libraries and development headers (Ubuntu's lib*-dev equivalents).
    # Nix splits headers/pkg-config metadata into separate development outputs.
    # This replicates the VS Code for R development guide.
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
