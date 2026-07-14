# Thanks to Zack Susswein for this .Rprofile
# This allows us to download binary packages on Linux.
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

# Set user library path
user_library <- file.path(
    "/home", 
    Sys.getenv("USER"), 
    "R", 
    "x86_64-pc-linux-gnu-library", 
    paste(R.version$major, sub("\\..*$", "", R.version$minor), sep = ".")
)

.libPaths(c(.libPaths(), user_library))
rm(user_library)

# pak is installed in home-manager
pak::repo_add(hubverse = 'https://hubverse-org.r-universe.dev');



system('echo "nix home-manager .Rprofile for user $USER loaded successfully" | lolcat')
cat("\n")