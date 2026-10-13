//! Loading our script into KWin through its scripting D-Bus API.

use std::path::{Path, PathBuf};

use anyhow::{Context, Result};
use zbus::blocking::Connection;

pub const PLUGIN_NAME: &str = "clockmost-bridge";
const SCRIPT: &str = include_str!("kwin_script.js");

/// KWin loads scripts from a file path, so the embedded script is written to the runtime dir first.
pub fn write_script() -> Result<PathBuf> {
    let dir = std::env::var_os("XDG_RUNTIME_DIR").context("XDG_RUNTIME_DIR is not set")?;
    let path = Path::new(&dir).join("clockmost-kwin-bridge.js");
    std::fs::write(&path, SCRIPT).with_context(|| format!("writing {}", path.display()))?;
    Ok(path)
}

fn scripting(conn: &Connection, method: &str, body: &(impl serde::Serialize + zbus::zvariant::DynamicType)) -> Result<zbus::Message> {
    conn.call_method(Some("org.kde.KWin"), "/Scripting", Some("org.kde.kwin.Scripting"), method, body)
        .with_context(|| format!("KWin Scripting.{method}"))
}

/// Replace any copy left by an earlier run, then load and start ours.
pub fn load(conn: &Connection, path: &Path) -> Result<()> {
    unload(conn)?;
    let path = path.to_str().context("script path is not UTF-8")?;
    let id: i32 = scripting(conn, "loadScript", &(path, PLUGIN_NAME))?.body().deserialize()?;
    anyhow::ensure!(id >= 0, "KWin refused the script (id {id})");
    scripting(conn, "start", &())?;
    Ok(())
}

pub fn unload(conn: &Connection) -> Result<()> {
    scripting(conn, "unloadScript", &(PLUGIN_NAME,))?;
    Ok(())
}
