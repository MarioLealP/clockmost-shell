# clockmost-shell

The Endfield desktop shell for the Linux desktop (CachyOS + KDE Plasma/KWin): our own top bar and control
center in Quickshell, replacing the Noctalia stand-in (Mario 2026-10-13: "just remake it, we can make our own
control center"). Design source: the mocks in `Benylin/clockmost-desktop` (`ds-topbar-v2.html`, ...).

- `bridge/` - `kwin-bridge` (Rust): KWin has no workspace/window-list Wayland protocol for Quickshell, so it loads
  a KWin script that sends JSON snapshots over D-Bus (`org.clockmost.KWinBridge`), printed one per line on
  stdout for the bar. Workspace switching goes straight to KWin's `/VirtualDesktopManager`.
- `shell/` - the Quickshell config (bar, control center). Coming next.

Build the bridge: `cd bridge && cargo build --release` (checks: `just check`).
