//! kwin-bridge: feeds KWin's desktops and windows to the clockmost Quickshell bar.
//!
//! KWin doesn't offer the workspace / window-list Wayland protocols Quickshell reads, so a small
//! KWin script (kwin_script.js) sends a JSON snapshot here over D-Bus on every change, and this
//! process prints each snapshot as one line on stdout - the bar runs it and reads the lines.
//!
//! The other direction (the dock focusing / minimizing a window): the shell calls `Command` with a JSON
//! command, and the script long-polls `Next`, which hands it the next queued command.

mod kwin;

use std::io::Write;
use std::time::Duration;

use anyhow::Result;
use zbus::{blocking::connection, interface};

struct Bridge {
    tx: async_channel::Sender<String>,
    rx: async_channel::Receiver<String>,
}

/// `Next` answers empty after this long, inside callDBus's 25s default timeout: a timed-out call would end the
/// script's poll chain (KWin drops the callback on errors).
const POLL: Duration = Duration::from_secs(20);

fn emit(line: &str) {
    let mut out = std::io::stdout().lock();
    // stdout closed = the shell that started us is gone: exit instead of lingering as an orphan that keeps the
    // D-Bus name (a restarted shell's bridge then replaces it)
    if writeln!(out, "{line}").and_then(|()| out.flush()).is_err() {
        std::process::exit(0);
    }
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

    /// From the shell: a window command for the script, e.g. {"op":"activate"|"minimize"|"close","id":"{uuid}"}.
    fn command(&self, json: String) {
        // unbounded, so this never blocks; the channel only closes with the process
        let _ = self.tx.try_send(json);
    }

    /// Long-polled by the KWin script: the next queued command, or "" after POLL so it can ask again.
    async fn next(&self) -> String {
        let recv = async { self.rx.recv().await.unwrap_or_default() };
        let idle = async {
            async_io::Timer::after(POLL).await;
            String::new()
        };
        futures_lite::future::or(recv, idle).await
    }
}

fn main() -> Result<()> {
    let conn = connection::Builder::session()?
        .name("org.clockmost.KWinBridge")?
        .serve_at("/Bridge", {
            let (tx, rx) = async_channel::unbounded();
            Bridge { tx, rx }
        })?
        .build()?;

    let script = kwin::write_script()?;
    kwin::load(&conn, &script)?;

    // Runs until the bar stops us; the script is unloaded again on the next start.
    loop {
        std::thread::park();
    }
}
