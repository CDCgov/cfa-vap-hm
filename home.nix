# pkgs lets us access the nix store, which has tons of packages you'd want to get with apt etc.
{pkgs, user, ...}: {
    home.username = user; # whats your username?
    home.homeDirectory = "/home/${user}"; # wheres the home folder? 
    home.stateVersion = "24.11"; # Comment out for error with "latest" version
    programs.home-manager.enable = true; # this allows us to rebuild/activate by just typing: home-manager switch
    
    # The heavy lifting is here - what packages do we want? No apt needed!
    home.packages = with pkgs; [
      # Basic utilities
      lolcat # rainbow cats
      cowsay # a cow that says
      screenfetch # gives you system info
      neovim # modern vim
      htop # system resource manager
      gh # github cli

      # Programming
      uv # python manager
      R # R programming language
      docker 
      podman
    ];
}