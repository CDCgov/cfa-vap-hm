# pkgs lets us access the nix store, which has tons of packages you'd want to get with apt etc.
{config, pkgs, user, homedir, release, lib, ...}: {

    nixpkgs.config = {
      allowUnfree = true;
    };
    # Username, homedirectory, and release are handled in flake.nix
    home.username = user;
    home.homeDirectory = homedir;
    home.stateVersion = release;
    home.activation.switchMessage = lib.hm.dag.entryAfter ["WriteBoundary"] ''
        ${pkgs.cowsay}/bin/cowsay -f dragon "CFA VAP Home Manager updated!" | ${pkgs.lolcat}/bin/lolcat
      '';

    # Programs and pkgs:

    # Programs are preferrable to "pkgs" if they exist due to configurability; 
    # However, there are far fewer software available as "programs"
    
    # All programs are pkgs under the hood, with additional config available
    
    # The only thing needed to install a program is to specify <program_name>.enable
    programs = {

      home-manager.enable = true;

      bat.enable = true;
      firefox.enable = true;
      git.enable = true;
      gh.enable = true; # github cli
      lazygit.enable = true;
      ripgrep.enable = true;
      nushell.enable = true;
      tmux.enable = true;
      uv.enable = true; # uv python manager

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
        oh-my-zsh = {
          enable = true;
          theme = "lambda";
        };
        shellAliases = {
          cb = "xclip -sel clipboard"; # pipe to this to add the command to the clipboard
          dll = "docker ps -aql | xargs -r docker logs"; # docker logs latest
          hms = "home-manager switch --flake ~/.config/home-manager/ --impure"; # switch from anywhere
          runlike = "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock assaflavie/runlike";
          runlike_latest = "docker ps -l -q | xargs -r -I{} docker run --rm -v /var/run/docker.sock:/var/run/docker.sock assaflavie/runlike {}";
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
    # (.Rprofile and R packages managed in R.nix)
    # most packages are installed here.
    # think of these as things you could install with apt on ubuntu
    home.packages = with pkgs; [
        
      # Basics
      btop # system resource manager
      cowsay # a cow that says
      eza # fancy ls alternative
      fd # file finder
      htop # legacy ststem resource manager
      jq # shell json parsing
      just
      lolcat # rainbow cats
      fastfetch # gives you system info
      tree # filesystem visualization
      xclip
      
      # GUI apps and IDEs
      emacs
      nautilus # gui file manager
      neovim-unwrapped
      ungoogled-chromium # chromium without google tracking
      dbeaver-bin

      # Dev/languages
      cargo
      cargo-binstall # binary installs for rust
      docker-compose
      docker-client
      gcc
      julia
      lazydocker
      nixfmt
      nodejs
      podman
      pre-commit
      python313 # note that uv is also installed in 'programs', above
      ruff # python formatter
      shellcheck # tool that checks and lints shell scripts
      shfmt # formats shell scripts; complements shellcheck

      # Azure
      azure-cli
      azure-storage-azcopy
      blobfuse
    ];
      
}
