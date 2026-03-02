# pkgs lets us access the nix store, which has tons of packages you'd want to get with apt etc.
{pkgs, ...}: {
    home.username = "qxk3"; # whats your username?
    home.homeDirectory = "/home/qxk3"; # wheres the home folder? 
    home.stateVersion = "24.11"; # Comment out for error with "latest" version
    programs.home-manager.enable = true; # this allows us to rebuild/activate by just typing: home-manager switch
    
    # The heavy lifting is here - what packages do we want? No apt needed!
    home.packages = with pkgs; [
      lolcat
      cowsay
      neovim
      htop
      gh
      uv
      R
      screenfetch
    ];
}