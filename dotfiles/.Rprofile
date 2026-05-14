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

system('echo "nix home-manager .Rprofile for user $USER loaded successfully" | lolcat')
cat("\n")