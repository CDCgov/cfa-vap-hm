mod config;
mod runner;
mod ui;

use anyhow::Result;
use clap::Parser;
use config::{find_repo, Config};

/// Select Home Manager modules and run optional setup scripts.
#[derive(Parser)]
#[command(version)]
struct Args {
    /// Print the selection and exit
    #[arg(long)]
    show: bool,
    /// Set a group's selection (repeatable); implies saving
    #[arg(long = "set", value_name = "GROUP=OPTION[,OPTION]")]
    assignments: Vec<String>,
    /// Restore manifest defaults; implies saving
    #[arg(long)]
    reset: bool,
    /// Run Home Manager switch afterwards and exit
    #[arg(long)]
    apply: bool,
}

fn run() -> Result<i32> {
    let args = Args::parse();
    let mut cfg = Config::load(find_repo())?;
    if args.show {
        println!("{}", cfg.describe());
        return Ok(0);
    }
    if args.assignments.is_empty() && !args.reset && !args.apply {
        return if ui::run(&mut cfg)? {
            runner::apply(&mut cfg)
        } else {
            Ok(0)
        };
    }
    for assignment in &args.assignments {
        println!("{}", cfg.assign(assignment)?);
    }
    if args.reset {
        cfg.reset();
        println!("Reset every group to its manifest default.");
    }
    if args.reset || !args.assignments.is_empty() {
        println!("{}", cfg.save()?);
    }
    if args.apply {
        runner::apply(&mut cfg)
    } else {
        Ok(0)
    }
}

fn main() {
    match run() {
        Ok(code) => std::process::exit(code),
        Err(err) => {
            eprintln!("error: {err:#}");
            std::process::exit(1);
        }
    }
}
