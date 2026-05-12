# pkgs lets us access the nix store, which has tons of packages you'd want to get with apt etc.
{config, pkgs, user, homedir, release, kickstart, lib, ...}: {
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
      neovim.enable = true;
      zsh = {
        enable = true;
        oh-my-zsh = {
          enable = true;
          theme = "lambda";
        };
        initContent = ''
        cowsay -f dragon "Welcome to CFA VAP Home Manager" | lolcat
        '';
      };

      firefox.enable = true;
      tmux.enable = true;
      nushell.enable = true;
      obsidian.enable = true;
      uv.enable = true;

    };
  
    xdg.configFile."nvim".source = kickstart;

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

      # Mount network drives
      # Under construction - not sure if this will work
      # Will let us include drive mounting in home-manager, but not quite declarative
      # home.file."nix-scripts/Mount-Drives.sh" = {
      #   executable = true;
      #   text = ''
      #   #!/usr/bin/bash
      #   mkdir -p ${config.home.homeDirectory}/P
      #   mkdir -p ${config.home.homeDirectory}/S
      #   mkdir -p ${config.home.homeDirectory}/U
      #   options=""
      #   mount -t cifs -o uid=$(id -u),gid=$(id -g),cruid=$(id -u),vers=3.0,user=$(id -un),sec=krb5 <network_drive_see_cdcent> ${config.home.homeDirectory}/P
      #   mount -t cifs -o uid=$(id -u),gid=$(id -g),cruid=$(id -u),vers=3.0,user=$(id -un),sec=krb5 <network_drive_see_cdcent> ${config.home.homeDirectory}/S
      #   mount -t cifs -o uid=$(id -u),gid=$(id -g),cruid=$(id -u),vers=3.0,user=$(id -un),sec=krb5 <network_drive_see_cdcent> ${config.home.homeDirectory}/U
      #   '';
      # };
      # TODO: can nix run this script on home-manager switch?
      # TODO: Does it require sudo always? Can we get permissions?)
      

      # Set ~/.Rprofile for out-of-the-box ubuntu R package binaries. 
      # Thanks to Zack Susswein for the code!
      home.file.".Rprofile".source = dotfiles/.Rprofile;
}
