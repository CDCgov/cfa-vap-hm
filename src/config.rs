use anyhow::{bail, Context, Result};
use serde::Deserialize;
use serde_json::Value;
use std::{
    collections::{BTreeMap, BTreeSet},
    env, fs,
    path::{Path, PathBuf},
};

pub const USER_STATE: &str = "modules/user-state.json";
const DEFAULT_STATE: &str = "modules/state.json";
const MANIFEST: &str = "modules/manifest.json";
pub type Selection = BTreeMap<String, Vec<String>>;

#[derive(Debug, Deserialize)]
pub struct Tool {
    pub id: String,
    pub title: String,
    pub description: String,
    pub path: String,
}

#[derive(Debug, Deserialize)]
pub struct Group {
    pub id: String,
    pub title: String,
    pub description: String,
    pub default: Vec<String>,
    pub options: Vec<Tool>,
}

#[derive(Deserialize)]
struct Manifest {
    groups: Vec<Group>,
}

pub struct Script {
    pub title: &'static str,
    pub description: &'static str,
    pub path: &'static str,
}

pub const SCRIPTS: &[Script] = &[
    Script {
        title: "Docker Engine",
        description: "Install Docker Engine (Ubuntu)",
        path: "utils/install_docker_engine.sh",
    },
    Script {
        title: "Mount VAP drives",
        description: "Mount network drives",
        path: "utils/mount_vap_drives.sh",
    },
];

pub struct Config {
    pub repo: PathBuf,
    pub groups: Vec<Group>,
    pub state: Selection,
    pub saved: Selection,
    pub source: Option<&'static str>,
    // One-shot actions are deliberately separate from persisted module selections.
    pub scripts: BTreeSet<usize>,
}

pub fn home() -> PathBuf {
    env::var_os("HOME").map(PathBuf::from).unwrap_or_default()
}

pub fn find_repo() -> PathBuf {
    if let Some(path) = env::var_os("HM_DIR").filter(|s| !s.is_empty()) {
        let path = PathBuf::from(path);
        let path = match path.strip_prefix("~") {
            Ok(rest) => home().join(rest),
            Err(_) => path,
        };
        return fs::canonicalize(&path).unwrap_or(path);
    }
    // The packaged binary must use the writable checkout, not its store source.
    if let Ok(cwd) = env::current_dir() {
        if cwd.join(MANIFEST).is_file() {
            return cwd;
        }
    }
    home().join(".config/home-manager")
}

impl Config {
    pub fn load(repo: PathBuf) -> Result<Self> {
        let path = repo.join(MANIFEST);
        let manifest: Manifest = serde_json::from_str(
            &fs::read_to_string(&path)
                .with_context(|| format!("cannot read {}", path.display()))?,
        )
        .with_context(|| format!("invalid manifest {}", path.display()))?;
        validate(&manifest.groups)?;
        let mut source = None;
        let mut raw = Value::Null;
        for rel in [USER_STATE, DEFAULT_STATE] {
            let path = repo.join(rel);
            match fs::read_to_string(&path) {
                Ok(text) => match serde_json::from_str(&text) {
                    Ok(value) => {
                        raw = value;
                        source = Some(rel);
                        break;
                    }
                    Err(err) => eprintln!("warning: ignoring unreadable {}: {err}", path.display()),
                },
                Err(err) if err.kind() == std::io::ErrorKind::NotFound => {}
                Err(err) => eprintln!("warning: ignoring unreadable {}: {err}", path.display()),
            }
        }
        let state = normalize(&manifest.groups, &raw);
        Ok(Self {
            repo,
            groups: manifest.groups,
            saved: state.clone(),
            state,
            source,
            scripts: BTreeSet::new(),
        })
    }

    pub fn dirty(&self) -> bool {
        self.state != self.saved || !self.scripts.is_empty()
    }

    pub fn selected(&self, group: usize, option: usize) -> bool {
        let group = &self.groups[group];
        self.state[&group.id].contains(&group.options[option].id)
    }

    pub fn toggle(&mut self, group: usize, option: usize) {
        let g = &self.groups[group];
        let id = &g.options[option].id;
        let selected = self.state.get_mut(&g.id).unwrap();
        if selected.contains(id) {
            selected.retain(|i| i != id);
        } else {
            selected.push(id.clone());
        }
        self.order();
    }

    fn order(&mut self) {
        for group in &self.groups {
            let selected = &self.state[&group.id];
            let ordered = group
                .options
                .iter()
                .filter(|o| selected.contains(&o.id))
                .map(|o| o.id.clone())
                .collect();
            self.state.insert(group.id.clone(), ordered);
        }
    }

    pub fn assign(&mut self, assignment: &str) -> Result<String> {
        let (id, value) = assignment
            .split_once('=')
            .context("--set expects GROUP=OPTION[,OPTION...]")?;
        let group = self
            .groups
            .iter()
            .find(|g| g.id == id.trim())
            .with_context(|| format!("unknown group {:?}", id.trim()))?;
        let wanted: Vec<String> = value
            .split(',')
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .map(str::to_owned)
            .collect();
        for option in &wanted {
            if !group.options.iter().any(|o| o.id == *option) {
                bail!("unknown option {option:?} for {}", group.id);
            }
        }
        let message = format!(
            "{} -> {}",
            group.title,
            if wanted.is_empty() {
                "(none)".into()
            } else {
                wanted.join(", ")
            }
        );
        self.state.insert(group.id.clone(), wanted);
        self.order();
        Ok(message)
    }

    pub fn reset(&mut self) {
        self.state = self
            .groups
            .iter()
            .map(|g| (g.id.clone(), g.default.clone()))
            .collect();
        self.order();
        self.scripts.clear();
    }

    pub fn save(&mut self) -> Result<String> {
        let path = self.repo.join(USER_STATE);
        let tmp = path.with_file_name("user-state.json.tmp");
        fs::write(&tmp, serde_json::to_string_pretty(&self.state)? + "\n")
            .with_context(|| format!("cannot write {}", tmp.display()))?;
        fs::rename(&tmp, &path).with_context(|| format!("cannot replace {}", path.display()))?;
        self.saved = self.state.clone();
        self.source = Some(USER_STATE);
        Ok(format!("saved {USER_STATE} - run `hms` to apply"))
    }

    pub fn describe(&self) -> String {
        let mut lines = vec![format!("repo: {}", self.repo.display())];
        for (gi, group) in self.groups.iter().enumerate() {
            lines.push(format!(
                "{}: {} - {}",
                group.id, group.title, group.description
            ));
            lines.push(format!("    default: {}", group.default.join(", ")));
            for (oi, option) in group.options.iter().enumerate() {
                let mark = if self.selected(gi, oi) { "[x]" } else { "[ ]" };
                lines.push(format!("  {mark} {:<11} {}", option.id, option.description));
            }
        }
        let origin = match self.source {
            Some(USER_STATE) => "personal overrides",
            Some(_) => "tracked defaults",
            None => "manifest defaults",
        };
        lines.push(format!(
            "state: {} ({origin}){}",
            self.source.unwrap_or(DEFAULT_STATE),
            if self.dirty() {
                " - unsaved changes"
            } else {
                ""
            }
        ));
        lines.join("\n")
    }
}

fn validate(groups: &[Group]) -> Result<()> {
    if groups.is_empty() {
        bail!("manifest must declare at least one group");
    }
    let mut group_ids = BTreeSet::new();
    for group in groups {
        let ids: BTreeSet<_> = group.options.iter().map(|o| &o.id).collect();
        if !group_ids.insert(&group.id) || group.id == "scripts" {
            bail!("duplicate or reserved group id {:?}", group.id);
        }
        if ids.is_empty() || ids.len() != group.options.len() {
            bail!("group {} must have unique, non-empty options", group.id);
        }
        if group.default.iter().any(|id| !ids.contains(id)) {
            bail!("group {} has unknown defaults", group.id);
        }
        for option in &group.options {
            if Path::new(&option.path).is_absolute() {
                bail!("module paths must be relative");
            }
        }
    }
    Ok(())
}

fn normalize(groups: &[Group], raw: &Value) -> Selection {
    groups
        .iter()
        .map(|group| {
            let selected = raw
                .get(&group.id)
                .and_then(Value::as_array)
                .and_then(|items| {
                    let ids: Option<Vec<_>> = items.iter().map(Value::as_str).collect();
                    let ids: Vec<_> = ids?
                        .into_iter()
                        .filter(|id| !(group.id == "options" && *id == "omz"))
                        .collect();
                    ids.iter()
                        .all(|id| group.options.iter().any(|o| o.id == *id))
                        .then_some(ids)
                });
            let selected =
                selected.unwrap_or_else(|| group.default.iter().map(String::as_str).collect());
            let ordered = group
                .options
                .iter()
                .filter(|o| selected.contains(&o.id.as_str()))
                .map(|o| o.id.clone())
                .collect();
            (group.id.clone(), ordered)
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn normalization_preserves_legacy_choices_and_rejects_invalid_groups() {
        let manifest: Manifest =
            serde_json::from_str(include_str!("../modules/manifest.json")).unwrap();
        let state = normalize(
            &manifest.groups,
            &serde_json::json!({"options": ["omz", "rust", "editors", "rust"]}),
        );
        assert_eq!(state["options"], ["editors", "rust"]);
        for raw in [
            serde_json::json!({"options": ["unknown"]}),
            serde_json::json!({"options": false}),
            Value::Null,
        ] {
            let state = normalize(&manifest.groups, &raw);
            assert_eq!(state["options"].len(), manifest.groups[0].default.len());
        }
        assert!(
            normalize(&manifest.groups, &serde_json::json!({"options": []}))["options"].is_empty()
        );
    }
}
