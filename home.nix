# pkgs lets us access the nix store, which has tons of packages you'd want to get with apt etc.
{config, pkgs, user, homedir, release, lib, lazyvim, ...}: {

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
    
    # Custom program - lazyvim
    imports = [ lazyvim.homeManagerModules.default ];
    programs.lazyvim = {
      enable = true;
      extras = {
        lang.nix.enable = true;
        lang.python = {
          enable = true;
          installDependencies = true;        # Install ruff
          installRuntimeDependencies = true; # Install python3
        };
      };
    };
    # Programs available on nixpkgs go here
    programs = {

      home-manager.enable = true;
      zsh = {
        enable = true;
        oh-my-zsh = {
          enable = true;
          theme = "lambda";
        };
        shellAliases = {
          hms = "home-manager switch --impure";
          docker_logs_latest = "docker ps -aql | xargs -r docker logs";
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

      firefox.enable = true;
      tmux.enable = true;
      nushell.enable = true;
      uv.enable = true;

    };
  
    # home directory dotfiles
    home.file.".Rprofile".source = dotfiles/.Rprofile;

    # most packages are installed here.
    # think of these as things you could install with apt on ubuntu
    home.packages = with pkgs; [
        
        # Basics
        cowsay # a cow that says
        git
        gh # github cli
        htop # system resource manager
        jq # shell json parsing
        just
        lolcat # rainbow cats
        screenfetch # gives you system info
        tree # filesystem visualization
        xclip
        
        # GUI apps and IDEs
        emacs
        nautilus # gui file manager
        neovim-unwrapped
        rstudio 

        # Dev/languages
        cargo
        cargo-binstall # binary installs for rust
        gcc
        julia
        nodejs
        podman
        pre-commit
        python313
        R
        ruff

        # Azure
        azure-cli
        azure-storage-azcopy
      ];
      
}
