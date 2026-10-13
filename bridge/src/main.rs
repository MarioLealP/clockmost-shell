//! kwin-bridge: feeds KWin's desktops and windows to the clockmost Quickshell bar.
//!
//! KWin doesn't offer the workspace / window-list Wayland protocols Quickshell reads, so a small
//! KWin script (kwin_script.js) sends a JSON snapshot here over D-Bus on every change, and this
//! process prints each snapshot as one line on stdout - the bar runs it and reads the lines.

mod kwin;

use std::io::Write;

use anyhow::Result;
use zbus::{blocking::connection, interface};

struct Bridge;

fn emit(line: &str) {
    let mut out = std::io::stdout().lock();
    // stdout closing means the bar went away; nothing useful to do about it here
    let _ = writeln!(out, "{line}");
    let _ = out.flush();
}

#[interface(name = "org.clockmost.KWinBridge")]
impl Bridge {
    /// Called by the KWin script with a JSON snapshot.
    fn update(&self, json: String) {
        emit(&json);
    }

    /// Bound to a Win-key tap in KWin (kwinrc [ModifierOnlyShortcuts] Meta): asks the bar to reveal itself.
    fn reveal(&self) {
        emit(r#"{"event":"reveal"}"#);
    }
}

fn main() -> Result<()> {
    let conn = connection::Builder::session()?
        .name("org.clockmost.KWinBridge")?
        .serve_at("/Bridge", Bridge)?
        .build()?;

    let script = kwin::write_script()?;
    kwin::load(&conn, &script)?;

    // Runs until the bar stops us; the script is unloaded again on the next start.
    loop {
        std::thread::park();
    }
}
