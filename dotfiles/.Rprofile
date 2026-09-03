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

options(
    repos = c(
        CRAN = "https://p3m.dev/cran/__linux__/manylinux_2_28/latest",
        getOption("repos")
    )
)

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
