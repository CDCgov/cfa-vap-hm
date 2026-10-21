use std::{fs, path::PathBuf, process::Command};

struct Checkout(PathBuf);
impl Checkout {
    fn new() -> Self {
        let dir = std::env::temp_dir().join(format!("cfa-vap-cli-test-{}", std::process::id()));
        fs::create_dir_all(dir.join("modules")).unwrap();
        fs::write(
            dir.join("modules/manifest.json"),
            include_str!("../modules/manifest.json"),
        )
        .unwrap();
        fs::write(
            dir.join("modules/state.json"),
            include_str!("../modules/state.json"),
        )
        .unwrap();
        Self(dir)
    }
    fn run(&self, args: &[&str]) -> std::process::Output {
        Command::new(env!("CARGO_BIN_EXE_cfa-vap-tui"))
            .env("HM_DIR", &self.0)
            .args(args)
            .output()
            .unwrap()
    }
}
impl Drop for Checkout {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}

#[test]
fn cli_saves_reloads_resets_and_handles_invalid_input() {
    let repo = Checkout::new();
    let output = repo.run(&["--set", "options=rust,editors,rust"]);
    assert!(
        output.status.success(),
        "{}",
        String::from_utf8_lossy(&output.stderr)
    );
    let path = repo.0.join("modules/user-state.json");
    let saved = fs::read_to_string(&path).unwrap();
    let state: serde_json::Value = serde_json::from_str(&saved).unwrap();
    assert_eq!(state["options"], serde_json::json!(["editors", "rust"]));
    assert!(state.get("scripts").is_none());
    let output = repo.run(&["--show"]);
    let text = String::from_utf8(output.stdout).unwrap();
    assert!(text.contains("[x] rust") && text.contains("personal overrides"));
    assert!(!repo.run(&["--set", "options=unknown"]).status.success());
    assert_eq!(fs::read_to_string(&path).unwrap(), saved);
    assert!(repo.run(&["--set", "options="]).status.success());
    assert!(repo.run(&["--reset"]).status.success());
    let state: serde_json::Value =
        serde_json::from_str(&fs::read_to_string(&path).unwrap()).unwrap();
    assert!(state["options"].as_array().unwrap().len() > 2);
    fs::write(&path, "broken JSON").unwrap();
    let output = repo.run(&["--show"]);
    assert!(output.status.success());
    assert!(String::from_utf8_lossy(&output.stdout).contains("tracked defaults"));
    assert!(String::from_utf8_lossy(&output.stderr).contains("warning:"));
}
