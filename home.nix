{ config, pkgs, user, homedir, ... }:

{
  nixpkgs.config = {
      allowUnfree = true;
  };
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = user;
  home.homeDirectory = "/home/${homedir}";
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    git
    google-chrome
    gnome-themes-extra
    ripgrep
    neovim
    nodejs_22
    rustup
    nixfmt-rfc-style
    python313
    pre-commit
    detect-secrets
    ruff
    authenticator
    uv
    jq
    tree
    gemini-cli
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    "Documents/NIDA/.gitconfig".text = ''
    [user]
	email = rellag@nida.nih.gov
    '';
    "Documents/CDC/.gitconfig".text = ''
    [user]
        email = ap82@cdc.gov
    '';
    ".gitconfig".text = ''
    [init]
        defaultBranch = main

    [credential]
        helper = store

    [user]
        name = Giovanni Rella
        email = giomrella@gmail.com

    [includeIf "gitdir:~/Documents/NIDA/**"]
        path = ~/Documents/NIDA/.gitconfig

    [includeif "gitdir:~/Documents/CDC/**"]
        path = "~/Documents/CDC/.gitconfig"

    '';
    ".vimrc".text = ''
      set number relativenumber ruler showcmd wildmenu
      " allow :find command to search all files from root
      set path+=**
      " include .github folder in :find
      set path+=.github/**
    '';
    ".bash_profile".text = ''
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
    '';
    ".bashrctest".text = ''
    # the below gives a shell level counter in the prompt string to see if you have 
    # nested `nix-shell` or `nix develop` shells
    PS1="''${PS1//\\u/"$SHLVL:\\u"}"
    if command -v tmux > /dev/null && [ -n "PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
      exec tmux
    fi
    alias ehome="nvim ~/.config/home-manager/home.nix"
    alias ll="ls -lah --color=auto"
    '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/gio/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.tmux = {
       enable = true;
       clock24 = true;
       terminal = "tmux-256color";
       extraConfig = ''
         set-option -ga terminal-overrides ",*256col*:Tc:RGB"
         set-window-option -g mode-keys vi
         bind -T copy-mode-vi v send -X begin-selection
         bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
         bind P run-shell "tmux save-buffer /tmp/tmux-buffer && xclip -sel clipboard /tmp/tmux-buffer"
         set-option -sg escape-time 10
         set-option -g default-terminal "screen-256color"
         bind c new-window -c "#{pane_current_path}"
         bind '"' split-window -c "#{pane_current_path}"
         bind % split-window -h -c "#{pane_current_path}"
         bind-key Up select-pane -U
         bind-key Down select-pane -D
         bind-key Left select-pane -L
         bind-key Right select-pane -R
       '';
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 10;
    };
  };

}
