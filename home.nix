# pkgs lets us access the nix store, which has tons of packages you'd want to get with apt etc.
{config, pkgs, user, homedir, ...}: {
    nixpkgs.config = {
      allowUnfree = true;
    };
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = user;
    home.homeDirectory = homedir;
    home.stateVersion = "25.05"; # Comment out for error with "latest" version
    programs.home-manager.enable = true; # this allows us to rebuild/activate by just typing: home-manager switch
    
    # The heavy lifting is here - what packages do we want? No apt needed!
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

      # Programming
      uv # python manager
      R # R programming language
    ];
}