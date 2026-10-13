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

## Control center (built so far)

One panel dropping under the bar, centred on the widget / pointer that opened it (kept on screen; slides when
re-targeted; below the clock plate with a tether when it would overlap it), vertical tab rail (Mario: "the vertical side bar noctalia has, so i can swap
between"): HOME / AUDIO / NETWORK / BLUETOOTH / MEDIA / CALENDAR / NOTIFICATIONS / CLIPBOARD. Bar widgets open their
tab (volume icon = home, middle-click = mute; clock = calendar; now playing = media; bluetooth; VPN = network; bell;
clipboard), right-click on the bar = home, outside click / Esc closes. IPC:
`quickshell ipc --pid <pid> call controlcenter open|toggle <tab>`, `openAt <tab> <x>`, `close`. Done: HOME (= the quick-settings mock;
live ethernet, bluetooth, VPN via nmcli, night light via kwinrc NightColor, output/mic levels, now playing; DND and
game mode wait for notifications / gamemode); AUDIO (output/input device pickers + levels, per-app volume/mute with a live
  PwNodePeakMonitor line); NETWORK (wired card: connection name, interface, speed, IPv4/gateway/DNS/MAC from nmcli,
  connect/disconnect; Wi-Fi list + switch when a Wi-Fi device exists - known/open networks only, PSK entry later,
  untested in the wired VM; every NM vpn/wireguard connection with a switch); BLUETOOTH (adapter switch, paired devices
  with type icon / battery / click = connect-disconnect, SCAN + click-to-pair; needs `bluez` + `bluetooth.service` -
  the VM has neither, so only the empty state is tested); CALENDAR (= the calendar mock: month nav, ISO week column, today
  boxed, weekends dim; UPCOMING empty until a calendar source is picked); CLIPBOARD (= the clipboard mock: Klipper history over
  D-Bus - text only, no per-item delete; our own pins in ~/.local/state/clockmost-shell/clip-pins.json; type tags TXT/URL/
  CMD/HEX; type to search, Up/Down, Enter = copy + close, Ctrl+P pin, Del unpin). Shared parts: CCTab (footer pinned, min height = rail), CCHeader, CCFooter, DeviceRow.
  MEDIA waits for the Spotify skin (Mario 2026-10-13): lyrics + up-next aren't in MPRIS, so they likely come from a
  Spicetify extension in that skin - build both together. Other tabs: placeholders, built next one at a time.

## Control center scope (Mario 2026-10-13)

Panels drop from their bar widget, styled from the mocks in `ds-topbar-v2.html?state=...`:
quick settings (`quick`, user chip / right-click), calendar (`cal`, clock plate), media (`media`, now playing),
notifications (`notif` + popups `pop`, bell), clipboard (`clip`, Klipper). Detail views (important): audio
(devices + per-app volume), network, bluetooth - opened from quick-settings tiles, inside the same panel.
Nice to have: weather forecast. Not wanted: monitor/brightness, system monitor, screen time, power.
Compared to Noctalia's 12 control-center tabs: mocks cover 4 fully, 3 partly (those three detail views), 5 dropped.
