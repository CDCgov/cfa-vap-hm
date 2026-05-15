# pkgs lets us access the nix store, which has tons of packages you'd want to get with apt etc.
{config, pkgs, user, homedir, release, lib, ...}: {
    nixpkgs.config = {
      allowUnfree = true;
    };
    # Username, homedirectory, and release are handled in flake.nix
    home.username = user;
    home.homeDirectory = homedir;
    home.stateVersion = release;

    # Programs and pkgs:

    # Programs are preferrable to "pkgs" if they exist due to configurability; 
    # However, there are far fewer software available as "programs"
    
    # All programs are pkgs under the hood, with additional config available
    
    # The only thing needed to install a program is to specify <program_name>.enable
    
    programs = {

      home-manager.enable = true;
      zsh = {
        enable = true;
        oh-my-zsh = {
          enable = true;
          theme = "lambda";
        };
        shellAliases = {
          runlike = "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock assaflavie/runlike";
          runlike_latest = "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock assaflavie/runlike \"$(docker ps -l -q)\"";
          docker_logs_latest = "docker logs \"$(docker ps -aql)\"";
        };
        initContent = ''
        cowsay -f dragon "Welcome to the CFA VAP" | lolcat

        # .vaprc is a personal rc file not managed by home-manager
        # add to your ~/.vaprc any commands/aliases/shell-config 
        # you want for yourself alone
        touch ~/.vaprc
        source ~/.vaprc
        '';
      };

      firefox.enable = true;
      tmux.enable = true;
      nushell.enable = true;
      uv.enable = true;

    };
  
    # .config/ files

    # home directory dotfiles
    home.file.".Rprofile".source = dotfiles/.Rprofile;

    # most packages are installed here.
    # think of these as things you could install with apt on ubuntu
    home.packages = with pkgs; [
        # Basic utilities
        lolcat # rainbow cats
        cowsay # a cow that says
        screenfetch # gives you system info
        htop # system resource manager
        git
        gh # github cli
        jq # shell json parsing
        tree # filesystem visualization
        xclip
        just
        
        # GUI apps
        rstudio 
        nautilus # gui file manager

        # Development
        neovim-unwrapped
        cargo
        cargo-binstall # binary installs for rust
        python313
        R
        julia
        nodejs
        pre-commit
        ruff
        podman
        gcc
        emacs

        # Azure
        azure-cli
        azure-storage-azcopy
      ];
      
}
