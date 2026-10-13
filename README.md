# clockmost-shell

The Endfield desktop shell for the Linux desktop (CachyOS + KDE Plasma/KWin): our own top bar and control
center in Quickshell, replacing the Noctalia stand-in (Mario 2026-10-13: "just remake it, we can make our own
control center"). Design source: the mocks in `Benylin/clockmost-desktop` (`ds-topbar-v2.html`, ...).

- `bridge/` - `kwin-bridge` (Rust): KWin has no workspace/window-list Wayland protocol for Quickshell, so it loads
  a KWin script that sends JSON snapshots over D-Bus (`org.clockmost.KWinBridge`), printed one per line on
  stdout for the bar. Workspace switching goes straight to KWin's `/VirtualDesktopManager`.
- `shell/` - the Quickshell config. Run: `quickshell -p shell` (in the VM: `~/src/clockmost-shell/shell`).
  Done: the bar frame (band + hatch + ruler, CLOCKMOST mark, wings, crosshair ring, the hanging clock plate with live
  time/date + tri-band, band blur via ext-background-effect), Felt chip (static), live workspace chips from
  kwin-bridge (click = switch, app-coloured window marks, attention diamond), live wing; right side: now playing (MPRIS,
  first playing player, art, elapsed, animated meter), weather (location from the IP via ipinfo.io + Open-Meteo, no keys;
  on a VPN = exit location), status tray (volume live via PipeWire, click = mute), user chip. Wings shrink to fit (line first, then the print) and fade out when even that won't fit.
  Design target = 1080p (1:1 with the mock); wider screens (the 3440 ultrawide) keep edge-anchored groups for now,
  the empty band gets extra detail later (Mario 2026-10-13). Narrower than 1920 = the whole bar scales down.
  Smart hide (Mario 2026-10-13, like Noctalia's): shown while no window covers the band+plate area, slides away
  when covered; Win tap (kwinrc `[ModifierOnlyShortcuts] Meta=org.clockmost.KWinBridge,/Bridge,org.clockmost.KWinBridge,Reveal`)
  or the pointer on the top-edge strip reveals it; leaving hides it again. No reserved space. Motion: band 220ms
  OutCubic; reveal = plate first (280ms OutQuart, no bounce), band + groups +90ms; hide mirrors.
  Next (was: the right side (now
  playing, weather, tray, user), the reveal motion, then the control center. Bar scales down below 1920px wide (VM).
  Bridge binary lives at `~/.local/bin/kwin-bridge`.
  Gotcha: QtSvg (SVG Tiny) ignores `rgba()` stroke colours - assets use `#rrggbb` + `stroke-opacity`.

Build the bridge: `cd bridge && cargo build --release` (checks: `just check`).
