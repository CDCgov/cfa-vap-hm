# pkgs lets us access the nix store, which has tons of packages you'd want to get with apt etc.
{config, pkgs, user, homedir, release, ...}: {
    nixpkgs.config = {
      allowUnfree = true;
    };
    # Username, homedirectory, and release are handled in flake.nix
    home.username = user;
    home.homeDirectory = homedir;
    home.stateVersion = release; 
    
    # Programs and pkgs:

    # programs are preferrable to "pkgs" if they exist due to configurability; 
    # however, there are far fewer software available as "programs"
    # All programs are pkgs under the hood, with additional config available
    programs = {

      home-manager.enable = true;

      zsh = {
        enable = true;
        oh-my-zsh = {
          enable = true;
          theme = "lambda";
        };
      };

      firefox.enable = true;
      docker-cli.enable = true;
      vscode.enable = true;
      tmux.enable = true;
      nushell.enable = true;
      obsidian.enable = true;
      uv.enable = true;

    };
  
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
        
        # GUI apps
        rstudio 
        nautilus # gui file manager

        # Development
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
        neovim
        emacs

        # Azure
        azure-cli
        azure-storage-azcopy
      ];
}
