# pkgs lets us access the nix store, which has tons of packages you'd want to get with apt etc.
{config, pkgs, user, homedir, ...}: {
    nixpkgs.config = {
      allowUnfree = true;
    };
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = user;
    home.homeDirectory = homedir;
    home.stateVersion = "25.11"; # Comment out for error with "latest" version
    
    # programs are preferrable to pkgs if they exist due to configurability; 
    # however, there are far fewer software available here
    # GUI apps, daemon-requiring apps, etc usually go here.
    # (there is not a strict delineation)
    programs = {

      home-manager.enable = true;

      zsh = {
        enable = true;
        oh-my-zsh = {
          enable = true;
          theme = "robbyrussell";
        };
      };

      firefox.enable = true;
      docker-cli.enable = true;
      vscode.enable = true;
      # cargo.enable = true; # released in unstable, not 25.11 or earlier
      tmux.enable = true;
      nushell.enable = true;
      obsidian.enable = true;
      uv.enable = true;

    };
  
    # most packages are installed here
    home.packages = with pkgs; [
      # Basic utilities
      lolcat # rainbow cats
      cowsay # a cow that says
      screenfetch # gives you system info
      neovim # modern vim
      htop # system resource manager
      git # git
      gh # github cli
      jq # shell json parsing
      tree # filesystem visualization
      azure-cli # azure cli!
      azure-storage-azcopy
      xclip
      podman

      # Programming
      cargo
      cargo-binstall
      python313
      R # R programming language
      julia
      nodejs # npm, node
      pre-commit
      ruff
    ];
}