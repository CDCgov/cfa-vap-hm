use crate::config::{Config, SCRIPTS};
use anyhow::{bail, Context, Result};
use std::{
    env,
    io::{self, Write},
    path::Path,
    process::{Command, Stdio},
};

fn on_path(program: &str) -> bool {
    env::var_os("PATH")
        .is_some_and(|path| env::split_paths(&path).any(|dir| dir.join(program).is_file()))
}

fn rainbow(text: &str) {
    let output = (|| -> Option<Vec<u8>> {
        let mut child = Command::new("lolcat")
            .args(["--force", "--seed", "1"])
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::null())
            .spawn()
            .ok()?;
        // Closing stdin is necessary for lolcat to finish.
        child.stdin.take()?.write_all(text.as_bytes()).ok()?;
        let result = child.wait_with_output().ok()?;
        result.status.success().then_some(result.stdout)
    })();
    let mut stdout = io::stdout().lock();
    let _ = stdout.write_all(output.as_deref().unwrap_or(text.as_bytes()));
    let _ = stdout.flush();
}

fn execute(command: &mut Command, label: &str) -> Result<i32> {
    let status = command
        .status()
        .with_context(|| format!("cannot run {label}"))?;
    Ok(status.code().unwrap_or(130))
}

// This runs only after the UI's terminal guard has restored cooked mode.
pub fn apply(cfg: &mut Config) -> Result<i32> {
    if cfg.state != cfg.saved {
        println!("{}", cfg.save()?);
    }
    let mut command;
    if on_path("home-manager") {
        command = Command::new("home-manager");
        command
            .args(["switch", "--flake"])
            .arg(format!("{}/", cfg.repo.display()))
            .arg("--impure");
    } else if on_path("nix") {
        command = Command::new("nix");
        command
            .arg("run")
            .arg(&cfg.repo)
            .args(["--", "switch", "--impure"]);
    } else {
        bail!("neither home-manager nor nix is on PATH - run hms yourself");
    }
    let display = std::iter::once(command.get_program())
        .chain(command.get_args())
        .map(|s| s.to_string_lossy())
        .collect::<Vec<_>>()
        .join(" ");
    rainbow(&format!("Applying: {display}\n"));
    let code = execute(&mut command, "Home Manager")?;
    if code != 0 {
        eprintln!("Home Manager switch failed (exit {code}). Your selection is saved; fix the error and run hms to retry.");
        return Ok(code);
    }
    println!("Applied - your environment now matches your saved selection.");
    run_scripts(cfg, |path| {
        execute(
            Command::new("bash").arg(path).current_dir(&cfg.repo),
            &path.display().to_string(),
        )
    })
}

fn run_scripts(cfg: &Config, mut run: impl FnMut(&Path) -> Result<i32>) -> Result<i32> {
    for (index, script) in SCRIPTS.iter().enumerate() {
        if cfg.scripts.contains(&index) {
            rainbow(&format!("Running: {}\n", script.description));
            let code = run(&cfg.repo.join(script.path))?;
            if code != 0 {
                eprintln!(
                    "{} failed (exit {code}); remaining scripts were not run.",
                    script.path
                );
                return Ok(code);
            }
        }
    }
    Ok(0)
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn scripts_are_opt_in_ordered_and_stop_on_failure() {
        let mut cfg = Config::load(Path::new(env!("CARGO_MANIFEST_DIR")).to_owned()).unwrap();
        assert_eq!(
            run_scripts(&cfg, |_| panic!("unselected script ran")).unwrap(),
            0
        );
        cfg.scripts.extend([1, 0]);
        let mut paths = vec![];
        assert_eq!(
            run_scripts(&cfg, |path| {
                paths.push(path.to_owned());
                Ok(0)
            })
            .unwrap(),
            0
        );
        assert!(paths[0].ends_with(SCRIPTS[0].path));
        assert!(paths[1].ends_with(SCRIPTS[1].path));
        let mut calls = 0;
        assert_eq!(
            run_scripts(&cfg, |_| {
                calls += 1;
                Ok(2)
            })
            .unwrap(),
            2
        );
        assert_eq!(calls, 1);
    }
}
