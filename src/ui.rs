use crate::config::{home, Config, SCRIPTS};
use anyhow::Result;
use crossterm::{
    event::{self, Event, KeyCode, KeyEventKind, KeyModifiers},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::Rect,
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::Paragraph,
    Frame, Terminal,
};
use std::{env, fs, io, path::PathBuf, process::Command};

const SUMMARY: &[&str] = &[
    "A reproducible CFA VAP development environment, managed by Nix and Home Manager.",
    "home.nix, including oh-my-zsh, is always on. Toggle extra tools here; defaults are just a starting point.",
    "Move with arrows or j/k; Space toggles. s saves, x restores defaults, and a saves, applies, and exits.",
    "Your choices live in modules/user-state.json. Saving alone does not change your environment; apply with a or hms.",
    "Scripts run last, outside Home Manager. They start unchecked and are never saved.",
    "Customize home.nix or modules/. Generations let you roll back; home-manager uninstall removes the managed setup.",
    "See README.md for installation, Docker trials, customization, and contributions.",
];

#[derive(Clone, Copy, Debug, PartialEq)]
enum Item {
    Module(usize, usize),
    Script(usize),
}

struct Row {
    line: Line<'static>,
    item: Option<Item>,
}

fn dim() -> Style {
    Style::default().add_modifier(Modifier::DIM)
}
fn heading() -> Style {
    Style::default()
        .fg(Color::Cyan)
        .add_modifier(Modifier::BOLD)
}

fn row(text: impl Into<String>, style: Style) -> Row {
    Row {
        line: Line::styled(text.into(), style),
        item: None,
    }
}

fn rows(cfg: &Config, width: u16) -> Vec<Row> {
    let mut rows = vec![];
    let separator = "─".repeat(width.saturating_sub(1) as usize);
    for (gi, group) in cfg.groups.iter().enumerate() {
        rows.push(row("", dim()));
        rows.push(row(
            format!(" {} - {}", group.title, group.description),
            heading(),
        ));
        // Partition explicitly, so a reordered manifest cannot mix the two tiers.
        for (default, label) in [
            (true, "Core tools (on by default)"),
            (false, "Optional (off by default)"),
        ] {
            let options: Vec<_> = group
                .options
                .iter()
                .enumerate()
                .filter(|(_, o)| group.default.contains(&o.id) == default)
                .collect();
            if options.is_empty() {
                continue;
            }
            if default {
                rows.push(row(separator.clone(), dim()));
            } else {
                rows.push(row("", dim()));
            }
            rows.push(row(
                format!("  {label}"),
                dim().add_modifier(Modifier::BOLD),
            ));
            for (oi, option) in options {
                let selected = cfg.selected(gi, oi);
                rows.push(Row {
                    line: Line::styled(
                        format!(
                            "  {} {:<17} {}",
                            if selected { "[x]" } else { "[ ]" },
                            option.title,
                            option.description
                        ),
                        if selected {
                            Style::default().fg(Color::Green)
                        } else {
                            dim()
                        },
                    ),
                    item: Some(Item::Module(gi, oi)),
                });
            }
        }
    }
    rows.push(row("", dim()));
    rows.push(row(
        " Scripts - Run last, after Home Manager applies.",
        heading(),
    ));
    rows.push(row(separator, dim()));
    for (i, script) in SCRIPTS.iter().enumerate() {
        let selected = cfg.scripts.contains(&i);
        rows.push(Row {
            line: Line::styled(
                format!(
                    "  {:<3} {:<17} {}",
                    if selected { "(!)" } else { "()" },
                    script.title,
                    script.description
                ),
                if selected {
                    Style::default().fg(Color::Green)
                } else {
                    dim()
                },
            ),
            item: Some(Item::Script(i)),
        });
    }
    rows
}

// Keep the cursor visible while restoring section headings at the beginning and
// filling the viewport after a resize. Cursor indexes only selectable items.
fn scroll(top: usize, cursor_row: usize, first_row: usize, count: usize, height: usize) -> usize {
    let height = height.max(1);
    let top = if cursor_row < top {
        cursor_row
    } else if cursor_row >= top + height {
        cursor_row + 1 - height
    } else {
        top
    };
    if cursor_row == first_row && first_row < height {
        0
    } else {
        top.min(count.saturating_sub(height))
    }
}

fn marker_path() -> PathBuf {
    env::var_os("XDG_STATE_HOME")
        .filter(|s| !s.is_empty())
        .map(PathBuf::from)
        .unwrap_or_else(|| home().join(".local/state"))
        .join("cfa-vap-hm/intro-seen")
}

struct App {
    cursor: usize,
    top: usize,
    info: bool,
    info_top: usize,
    marker: PathBuf,
    message: String,
    pending_quit: bool,
    banner: Vec<String>,
}

impl App {
    fn new() -> Self {
        let marker = marker_path();
        let banner = Command::new("figlet")
            .args(["-f", "slant", "CFA VAP  HM"])
            .output()
            .ok()
            .filter(|o| o.status.success())
            .map(|o| {
                String::from_utf8_lossy(&o.stdout)
                    .lines()
                    .map(str::to_owned)
                    .collect()
            })
            .unwrap_or_default();
        Self {
            cursor: 0,
            top: 0,
            info: !marker.exists(),
            info_top: 0,
            marker,
            message: String::new(),
            pending_quit: false,
            banner,
        }
    }

    fn draw(&mut self, frame: &mut Frame, cfg: &Config) {
        let area = frame.area();
        if area.height < 8 || area.width < 46 {
            frame.render_widget(
                Paragraph::new("Terminal too small - resize to at least 46x8."),
                area,
            );
            return;
        }
        let banner_height = self.banner.len() as u16;
        let fits = banner_height > 1
            && area.height >= banner_height + 14
            && self
                .banner
                .iter()
                .all(|s| s.len() + 2 <= area.width as usize);
        let header_y = if fits {
            for (y, line) in self.banner.iter().enumerate() {
                let spans: Vec<_> = line
                    .chars()
                    .enumerate()
                    .map(|(x, ch)| {
                        // Color directly: no subprocess ANSI parsing or curses pair bookkeeping.
                        let color = [
                            Color::LightRed,
                            Color::LightYellow,
                            Color::LightGreen,
                            Color::LightCyan,
                            Color::LightBlue,
                            Color::LightMagenta,
                        ][(x / 5 + y) % 6];
                        Span::styled(ch.to_string(), Style::default().fg(color))
                    })
                    .collect();
                put(frame, y as u16, Line::from(spans));
            }
            banner_height
        } else {
            put(
                frame,
                0,
                Line::styled(" CFA VAP - home-manager module toggle", heading()),
            );
            1
        };
        put(
            frame,
            header_y,
            Line::styled(format!(" {}", cfg.repo.display()), dim()),
        );
        let list_top = header_y + 1;
        if self.info {
            put(
                frame,
                list_top,
                Line::styled(" Welcome / Quick start", heading()),
            );
            let lines: Vec<String> = SUMMARY
                .iter()
                .flat_map(|p| {
                    let mut lines: Vec<_> =
                        textwrap::wrap(p, area.width.saturating_sub(4) as usize)
                            .into_iter()
                            .map(|s| format!("  {s}"))
                            .collect();
                    lines.push(String::new());
                    lines
                })
                .collect();
            let height = area.height.saturating_sub(list_top + 4) as usize;
            self.info_top = self.info_top.min(lines.len().saturating_sub(height));
            for (i, line) in lines.iter().skip(self.info_top).take(height).enumerate() {
                put(frame, list_top + 2 + i as u16, Line::raw(line.clone()));
            }
            put(
                frame,
                area.height - 1,
                Line::styled("i/Enter: tools  j/k/arrows: scroll  q: quit", dim()),
            );
            return;
        }
        let rows = rows(cfg, area.width);
        let selectable: Vec<_> = rows
            .iter()
            .enumerate()
            .filter(|(_, r)| r.item.is_some())
            .map(|(i, _)| i)
            .collect();
        self.cursor = self.cursor.min(selectable.len() - 1);
        let cursor_row = selectable[self.cursor];
        // Leave a blank line between the selections and the three-line footer,
        // including when the list is scrolled to its last script.
        let height = (area.height - list_top - 4) as usize;
        self.top = scroll(self.top, cursor_row, selectable[0], rows.len(), height);
        for (i, row) in rows.iter().enumerate().skip(self.top).take(height) {
            let mut line = row.line.clone();
            if i == cursor_row {
                line = line.style(Style::default().fg(Color::Black).bg(Color::White));
            }
            put(frame, list_top + (i - self.top) as u16, line);
        }
        let detail = match rows[cursor_row].item.unwrap() {
            Item::Module(g, o) => {
                let group = &cfg.groups[g];
                let option = &group.options[o];
                format!(
                    "{}/{} -> {}: {}",
                    group.id, option.id, option.path, option.description
                )
            }
            Item::Script(i) => format!("{}: {}", SCRIPTS[i].path, SCRIPTS[i].description),
        };
        put(frame, area.height - 3, Line::styled(detail, dim()));
        let status = if !self.message.is_empty() {
            self.message.clone()
        } else if !cfg.scripts.is_empty() && cfg.state == cfg.saved {
            "Scripts queued - press a to apply and run them.".into()
        } else if cfg.dirty() {
            "Unsaved changes - press s to save them.".into()
        } else {
            "Saved. Run hms or press a to apply.".into()
        };
        put(
            frame,
            area.height - 2,
            Line::styled(status, Style::default().fg(Color::Yellow)),
        );
        // Keep the primary action and info toggle visible on smaller terminals.
        let help = if area.width < 90 {
            "j/k: move  Space: toggle  s: save  x: reset  "
        } else {
            "j/k/arrows: move  Space: toggle  s: save  x: defaults  "
        };
        put(
            frame,
            area.height - 1,
            Line::from(vec![
                Span::styled(help, dim()),
                Span::styled(
                    "a: apply & quit",
                    if cfg.dirty() {
                        dim().fg(Color::Green)
                    } else {
                        dim()
                    },
                ),
                Span::styled("  i: info  q: quit", dim()),
            ]),
        );
    }

    fn remember_intro(&mut self) {
        if self.info && !self.marker.exists() {
            let result = fs::create_dir_all(self.marker.parent().unwrap())
                .and_then(|()| fs::write(&self.marker, ""));
            if let Err(err) = result {
                self.message = format!("Could not remember intro preference: {err}");
            }
        }
    }

    fn key(&mut self, key: KeyCode, cfg: &mut Config) -> Result<Option<bool>> {
        if key == KeyCode::Char('i') {
            self.info = !self.info;
            self.info_top = 0;
            self.pending_quit = false;
            return Ok(None);
        }
        if self.info {
            match key {
                KeyCode::Char('q' | 'Q') if !cfg.dirty() => return Ok(Some(false)),
                KeyCode::Char('q' | 'Q' | ' ') | KeyCode::Enter => self.info = false,
                KeyCode::Up | KeyCode::Char('k') => self.info_top = self.info_top.saturating_sub(1),
                KeyCode::Down | KeyCode::Char('j') => {
                    self.info_top = self.info_top.saturating_add(1)
                }
                _ => {}
            }
            return Ok(None);
        }
        if matches!(key, KeyCode::Char('q' | 'Q')) {
            if !cfg.dirty() || self.pending_quit {
                return Ok(Some(false));
            }
            self.pending_quit = true;
            self.message = "Unsaved changes - press q again to quit, or s to save first.".into();
            return Ok(None);
        }
        self.pending_quit = false;
        let items: Vec<_> = rows(cfg, 80).into_iter().filter_map(|r| r.item).collect();
        match key {
            KeyCode::Up | KeyCode::Char('k') => {
                self.cursor = self.cursor.saturating_sub(1);
                self.message.clear();
            }
            KeyCode::Down | KeyCode::Char('j') => {
                self.cursor = (self.cursor + 1).min(items.len() - 1);
                self.message.clear();
            }
            KeyCode::Home => {
                self.cursor = 0;
                self.top = 0;
            }
            KeyCode::End => self.cursor = items.len() - 1,
            KeyCode::Enter | KeyCode::Char(' ') => match items[self.cursor] {
                Item::Module(g, o) => {
                    cfg.toggle(g, o);
                    self.message.clear();
                }
                Item::Script(i) => {
                    if !cfg.scripts.remove(&i) {
                        cfg.scripts.insert(i);
                    }
                    self.message = "Scripts run on apply; selections are not saved.".into();
                }
            },
            KeyCode::Char('s') => {
                self.message = cfg.save()?;
                if !cfg.scripts.is_empty() {
                    self.message += "; scripts remain queued for a (not saved).";
                }
            }
            KeyCode::Char('a') => return Ok(Some(true)),
            KeyCode::Char('x') => {
                cfg.reset();
                self.message = "Reset to manifest defaults (not saved yet).".into();
            }
            _ => {}
        }
        Ok(None)
    }
}

fn put(frame: &mut Frame, y: u16, line: Line<'_>) {
    let area = frame.area();
    if y < area.height {
        frame.render_widget(Paragraph::new(line), Rect::new(0, y, area.width, 1));
    }
}

struct TerminalGuard;
impl Drop for TerminalGuard {
    fn drop(&mut self) {
        let _ = disable_raw_mode();
        let _ = execute!(io::stdout(), LeaveAlternateScreen, crossterm::cursor::Show);
    }
}

pub fn run(cfg: &mut Config) -> Result<bool> {
    // Restore the terminal even if drawing, persistence, or input fails.
    let previous = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |info| {
        let _ = disable_raw_mode();
        let _ = execute!(io::stdout(), LeaveAlternateScreen, crossterm::cursor::Show);
        previous(info);
    }));
    enable_raw_mode()?;
    let _guard = TerminalGuard;
    execute!(io::stdout(), EnterAlternateScreen)?;
    let mut terminal = Terminal::new(CrosstermBackend::new(io::stdout()))?;
    let mut app = App::new();
    loop {
        terminal.draw(|frame| app.draw(frame, cfg))?;
        if terminal.size()?.height >= 8 && terminal.size()?.width >= 46 {
            app.remember_intro();
        }
        if let Event::Key(key) = event::read()? {
            if key.kind == KeyEventKind::Release {
                continue;
            }
            if key.modifiers.contains(KeyModifiers::CONTROL) && key.code == KeyCode::Char('c') {
                return Ok(false);
            }
            if let Some(apply) = app.key(key.code, cfg)? {
                return Ok(apply);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ratatui::backend::TestBackend;

    #[test]
    fn scrolling_restores_headings_and_handles_resize() {
        assert_eq!(scroll(20, 5, 5, 35, 15), 0);
        assert_eq!(scroll(20, 30, 5, 35, 40), 0);
        assert_eq!(scroll(0, 5, 5, 35, 3), 3);
    }

    #[test]
    fn navigation_renders_all_tiers_and_returns_to_top() {
        let mut cfg = Config::load(PathBuf::from(env!("CARGO_MANIFEST_DIR"))).unwrap();
        let mut app = App::new();
        app.info = false;
        let mut terminal = Terminal::new(TestBackend::new(90, 18)).unwrap();
        for _ in 0..40 {
            app.key(KeyCode::Down, &mut cfg).unwrap();
        }
        terminal.draw(|f| app.draw(f, &cfg)).unwrap();
        assert!(app.top > 0);
        assert!(matches!(
            rows(&cfg, 90).iter().filter_map(|r| r.item).nth(app.cursor),
            Some(Item::Script(1))
        ));
        app.key(KeyCode::Char(' '), &mut cfg).unwrap();
        assert!(cfg.scripts.contains(&1));
        for _ in 0..40 {
            app.key(KeyCode::Up, &mut cfg).unwrap();
        }
        terminal.draw(|f| app.draw(f, &cfg)).unwrap();
        assert_eq!(app.top, 0);
        let buffer = terminal.backend().buffer();
        let rendered = buffer
            .content
            .iter()
            .map(|c| c.symbol())
            .collect::<String>();
        assert!(rendered.contains("Core tools (on by default)"));
        assert_eq!(app.key(KeyCode::Char('q'), &mut cfg).unwrap(), None);
        assert_eq!(app.key(KeyCode::Char('q'), &mut cfg).unwrap(), Some(false));
        app.info = true;
        assert_eq!(app.key(KeyCode::Char('i'), &mut cfg).unwrap(), None);
        assert!(!app.info);
        assert_eq!(app.key(KeyCode::Char('a'), &mut cfg).unwrap(), Some(true));
    }
}
