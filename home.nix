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
        initContent = ''
        cowsay -f dragon "Welcome to CFA VAP HM - now using zsh" | lolcat
        '';
      };

      firefox.enable = true;
      # docker-cli.enable = true;
      # vscode.enable = true;
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

      # Set ~/.Rprofile for out-of-the-box ubuntu R package binaries. 
      # Thanks to Zack Susswein for the code!
      home.file.".Rprofile".text = ''
        # Set default user agent header
        options(HTTPUserAgent = sprintf(
          "R/%s R (%s)", 
          getRversion(), 
          paste(getRversion(), 
          R.version["platform"], 
          R.version["arch"], 
          R.version["os"]))
        )

        # Also use this user agent header for wget and curl from within R
        options(download.file.extra = sprintf(
          "--header \"User-Agent: R (%s)\"", 
          paste(getRversion(), 
          R.version["platform"], 
          R.version["arch"], 
          R.version["os"]))
        )

        LINUX_VERSION = system("grep VERSION_CODENAME /etc/os-release | cut -d '=' -f2", intern = TRUE)

        options(
          repos = c(
            CRAN = sprintf(
              "https://packagemanager.rstudio.com/all/__linux__/%s/latest", 
              LINUX_VERSION
            ), 
            getOption("repos")
          )
        )

        rm(LINUX_VERSION)
        
        system('echo "nix home-manager .Rprofile for user $USER loaded succesfully" | lolcat')
        cat("\n")
      '';
}
