# clockmost-shell

The Endfield desktop shell for the Linux desktop (CachyOS + KDE Plasma/KWin): our own top bar and control
center in Quickshell, replacing the Noctalia stand-in (Mario 2026-10-13: "just remake it, we can make our own
control center"). Design source: the mocks in `Benylin/clockmost-desktop` (`ds-topbar-v2.html`, ...).

- `bridge/` - `kwin-bridge` (Rust): KWin has no workspace/window-list Wayland protocol for Quickshell, so it loads
  a KWin script that sends JSON snapshots over D-Bus (`org.clockmost.KWinBridge`), printed one per line on
  stdout for the bar. Workspace switching goes straight to KWin's `/VirtualDesktopManager`. Window commands go the
  other way: the shell calls `Command(json)` (`{"op":"activate"|"minimize"|"close","id":...}`), the script long-polls
  `Next` (answers "" after 20s, inside callDBus's 25s timeout) and runs them.
- `shell/` - the Quickshell config. Run: `quickshell -p shell` (in the VM: `~/src/clockmost-shell/shell`).
  Done: the bar frame (band + hatch + ruler, CLOCKMOST mark, wings, crosshair ring, the hanging clock plate with live
  time/date + tri-band, band blur via ext-background-effect), Felt chip (static), live workspace chips from
  kwin-bridge (click = switch, app-coloured window marks, attention diamond), live wing; right side: now playing (MPRIS,
  first playing player, art, elapsed, animated meter), weather (location from the IP via ipinfo.io + Open-Meteo, no keys;
  on a VPN = exit location), status tray (volume live via PipeWire, click = mute), user chip. Wings shrink to fit (line first, then the print) and fade out when even that won't fit.
  Design target = 1080p (1:1 with the mock); wider screens (the 3440 ultrawide) keep edge-anchored groups for now,
  the empty band gets extra detail later (Mario 2026-10-13). Narrower than 1920 = the whole bar scales down.
  Smart hide (Mario 2026-10-13, like Noctalia's): shown while no window covers the band+plate area, slides away
  when covered; a Win tap (the app drawer, which shows the bar while open - KWin global shortcut `clockmost-app-drawer`
  = Meta + Ctrl+Alt+Space, set by setup.d; kwinrc `[ModifierOnlyShortcuts]` never fired on metal) or the pointer on
  the top-edge strip reveals it; leaving hides it again. No reserved space. Motion: band 220ms
  OutCubic; reveal = plate first (280ms OutQuart, no bounce), band + groups +90ms; hide mirrors.
  Next (was: the right side (now
  playing, weather, tray, user), the reveal motion, then the control center. Bar scales down below 1920px wide (VM).
  Gotcha: QtSvg (SVG Tiny) ignores `rgba()` stroke colours - assets use `#rrggbb` + `stroke-opacity`.

## Package (pkgs/clockmost-shell, `[clockmost]` repo)

`pacman -S clockmost-shell`, then once as your user, in the Plasma session: `clockmost-desktop-setup`.
The package: `/usr/bin/kwin-bridge`, `/usr/bin/clockmost-autoscroll` + its system unit (enabled on install), the
Quickshell config in `/usr/share/clockmost-shell` started by `/etc/xdg/autostart/clockmost-shell.desktop`,
`org.clockmost.shell.desktop` (KWin's screencast grant for the dock previews), `/dev/uinput` for the autoscroll
service (`modules-load.d/clockmost-uinput.conf` + udev rule `60-clockmost-uinput.rules`: group input, applied on
install) and numlock on at the SDDM login screen (`/usr/lib/sddm/sddm.conf.d/zz-clockmost-numlock.conf`).
Opt out of the bar-only setup parts (Win, Win+V, panel removal) with a line `bar` in
`~/.config/clockmost/setup-off` - for when another shell is the bar.
`clockmost-desktop-setup` runs every `/usr/share/clockmost-desktop/setup.d/*.sh` (other clockmost desktop packages add
theirs): for this package Win = the app drawer (kglobalaccel; Plasma's launcher moved to Alt+F1), Meta+V off Klipper, the sycoca refresh, setting aside a dev
autostart entry, removing Plasma's own panels, `kxkbrc` from the system XKB layout (KWin on Wayland reads only that;
written once, a layout set in System Settings is kept) and numlock on at Plasma login (kcminputrc).
Dev: one Cargo workspace (`bridge/`, `autoscroll/`); `cargo build --release`, checks `just check`; run the shell
from the checkout with `quickshell -p shell` (a `kwin-bridge` earlier on PATH than /usr/bin wins). Release:
`release.sh X.Y.Z` (needs makepkg - run it on an Arch box) -> tag -> CI builds, scans, publishes.

## App tray (Mario 2026-10-14)

Left click = `activate(QsWindow.window)`: needs **`quickshell-clockmost`** (pkgs repo), which hands the app a
Wayland activation token first - with stock Quickshell an app can raise its window only the first time (2026-10-15).

The bar's right side: app tray, status tray, user chip; now playing moved left of the clock (media > arrow > clock -
Mario: "not enough space there for both media and tray and buttons"). `AppTray.qml` / `AppTrayIcon.qml`: the
StatusNotifier icons (`Quickshell.Services.SystemTray`; Plasma's kded6 is the watcher) on a plate like the status
tray, hidden while empty; 36px tiles, the app's own icon, underline orange = needs attention. Left = activate (menu
for menu-only items), right = the app's menu, middle = secondary activate, wheel = scroll. The menu is our own
(`TrayMenu` singleton + `TrayMenuWindow` per screen + `TrayMenuRow`, entries via `QsMenuOpener`): an overlay like the
control center (outside click / Esc closes), the dock plate material + shadow, head = app name in mono caps + rule,
rows Inter 12 (separators = rules, checks = yellow squares / radio diamonds, `›` submenus open in place with
`‹ BACK`), fade + 12px slide 180ms. Hover 500ms = the app's name in a small plate (PopupWindow).

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
  boxed, weekends dim; UPCOMING empty until a calendar source is picked); CLIPBOARD (= the clipboard mock: Klipper's history read from its
  database (history3.sqlite, read-only) - text AND images (thumbnail + size, IMG tag; picked = wl-copy of the PNG),
  real last-used ages; no per-item delete; our own pins in ~/.local/state/clockmost-shell/clip-pins.json; type tags TXT/URL/
  CMD/HEX; type to search, Up/Down, Enter = copy + close, Ctrl+P pin, Del unpin). Shared parts: CCTab (footer pinned, min height = rail), CCHeader, CCFooter, DeviceRow.
  MEDIA (= the media mock, ?state=media): cover on a slab of its colour, title / ARTIST / album + track no., visualizer
  strip (phonograph-audio's 48 cava bars over ws://127.0.0.1:47862, connected only while the panel is open) with the
  timer tag, click/drag seek bar, shuffle / prev / play / next / repeat (off -> all -> one), OPEN PHONOGRAPH (raises
  the player). Any MPRIS player; no lyrics, no up next (Mario 2026-10-14: both live only inside the Spotify page - not
  worth a page->shell channel). Accent = the cover's colour, shared with the bar chip (Media singleton): CoverSampler
  draws the cover at 24px on the bar and Media.pick() takes the strongest chroma-weighted hue at the mock lavender's
  lightness, grey covers stay quiet (Quickshell's ColorQuantizer only reads local files; covers are https). NOTIFICATIONS: the shell IS the notification server (claims org.freedesktop.Notifications at
  startup - Plasma's on-demand service is only a stub waiting for plasmashell's panel applet, which we don't have);
  popups (the mock's cards, top-right, 6s / critical stays, actions, progress hint, image) + the notification-centre
  tab (groups, CLEAR / CLEAR ALL, read on leaving), DND (critical still shows), bell diamond = unread.
  Autostart (VM): ~/.config/autostart/clockmost-shell.desktop; noctalia.desktop has Hidden=true.
  Other tabs: placeholders, built next one at a time.

## Control center scope (Mario 2026-10-13)

Panels drop from their bar widget, styled from the mocks in `ds-topbar-v2.html?state=...`:
quick settings (`quick`, user chip / right-click), calendar (`cal`, clock plate), media (`media`, now playing),
notifications (`notif` + popups `pop`, bell), clipboard (`clip`, Klipper). Detail views (important): audio
(devices + per-app volume), network, bluetooth - opened from quick-settings tiles, inside the same panel.
Nice to have: weather forecast. Not wanted: monitor/brightness, system monitor, screen time, power.
Compared to Noctalia's 12 control-center tabs: mocks cover 4 fully, 3 partly (those three detail views), 5 dropped.

## Autoscroll (autoscroll/, Mario 2026-10-14)

Windows-style middle-button autoscroll, **only for whitelisted apps** (Mario 2026-10-14: a system-wide version took
the middle button from every app - Firefox tab close, Discord links, drags - "we do whitelist"). `clockmost-autoscroll`
(Rust, evdev) grabs each mouse and re-emits it through a virtual twin untouched; on every middle press it asks the
shell (`query n` -> `toggle n` / `pass n`, 250ms, else pass) - at press time, so an app's middle-drag passes whole.
The shell answers toggle only when the window under the pointer (KWin, bridge op `cursor`; the shell's own layers
never match) is in `Autoscroll.autoscrollApps` - **empty for now**: Firefox (`general.autoScroll`) and Spotify (the
phonograph) have their own; with the list empty the shell answers pass without asking KWin. For a listed app: a plain
click = Windows' click-to-toggle (until the next click of any button, which is swallowed), held + moved = scroll while
held. System service under a DynamicUser in `input` (install/clockmost-autoscroll.service, binary in /usr/local/bin) -
the desktop user stays out of `input`, which can read keyboards. It tells the shell `start` / `dir x y` / `stop` on
/run/clockmost-autoscroll/events; the shell draws the anchor marker (Autoscroll + AutoscrollMarker). Handles relative
mice and absolute pointers (VMs). Hotplug: rescans for mice every 2s. The same service owns Win+V's paste keyboard.

Win+V (Mario 2026-10-14, "as windows as possible"): the CLIPBOARD tab at the pointer (KWin script shortcut ->
bridge event `clipboard` -> Clipboard.openAtPointer; Ctrl+Alt+V too, for the VM); picking pastes into the app you were
in - the service's own paste-only keyboard (KEY_LEFTCTRL + KEY_V, nothing else, at most every 300ms) presses Ctrl+V
when the shell sends `paste` on the socket. From the bar it only copies. Klipper's own Meta+V popup is unbound
(kglobalaccel setForeignShortcutKeys). Kitty pastes on right click
(mouse_map) since middle click is autoscroll now. System service under a DynamicUser in `input`
(install/clockmost-autoscroll.service, binary in /usr/local/bin) - the desktop user stays out of `input`, which can
read keyboards. It tells the shell `start` / `dir x y` / `stop` on /run/clockmost-autoscroll/events; the shell asks
KWin for the pointer position (bridge op `cursor`) and draws the anchor marker (Autoscroll + AutoscrollMarker).
Handles relative mice and absolute pointers (VMs). Hotplug: rescans for mice every 2s.

## App drawer (ds-app-drawer)

Win toggles it (the bridge's Meta-tap event) and the bar is shown while it's open; Esc / outside click / launching
closes it. Centred 980x600, white head fading to frosted glass, 7x3 sockets of 120px tiles (real icon or initial,
category code BRW/COM/MUS/..., colour underbar), search at the bottom (type, arrows, Enter). Apps = the .desktop
entries minus plumbing (`Apps.hidden`), ordered by launch count (~/.local/state/clockmost-shell/app-usage.json).
Motion per the mock: fade 280ms + slide up 60px over 500ms, then tiles fade in over their sockets (150ms); close
fades in place. IPC: `quickshell ipc --pid <pid> call drawer open|toggle|close`. More than 21 apps: whole-row
scrolling (wheel, arrows follow the selection, PageUp/PageDown = 3 rows) - sockets and glass holes stay put, tiles
step through them (180ms, 12px slide + fade), a 2px track with a yellow thumb right of the grid.
Icons: the app's own icon, greyscale at rest, colour on hover / keyboard selection (Mario). Keyboard selection only
shows once you type or use arrows. Keyboard focus is Exclusive from map time (switching it on as the window
appears left focus on the window below).

## Dock (ds-dock-v2)

The bar's partner at the bottom, per screen. Smart hide like the bar: shown while no window covers it, slides down
when covered (leaving the dashed handle); bottom edge / hover / the drawer being open bring it back. Contents:
DOCK cap, the drawer button (= Win), pinned apps | running unpinned apps, the RUNNING / WIN cap. The mock's
downloads stack became the task-manager button (same stacked-bars tile, Mario 2026-10-14; browsers don't publish
download totals, so it could never show progress): Plasma's System Monitor, or top in kitty until one's installed. Slot = tile with the app's own icon in true colour (Mario: no tinting), corner cut + underbar +
window-count bars in the app colour, orange diamond on attention / unread notifications, hover label; the focused
app lifts 10px with a yellow frame and pointer. Left click = launch / focus / minimize (cycles windows), middle =
new instance, right = pin / unpin. Pins: ~/.local/state/clockmost-shell/dock-pins.json (default = the mock's pins
that are installed).
Hover on an app with windows = the window preview panel (DockPreview + WindowCard, in the dock's plate material):
one card per window with a LIVE preview, title and an ACTIVE / MINIMIZED tag; click = focus that window, middle click = close it. Live
previews are KWin window screencasts (zkde_screencast) through KDE's own QML - `org.kde.taskmanager`
ScreencastingRequest + `org.kde.pipewire` PipeWireSourceItem, exactly what Plasma's taskbar tooltips use (Alt+Tab's
thumbnails only work inside KWin). KWin only grants the protocol to executables named by a desktop file:
install `install/org.clockmost.shell.desktop` to `~/.local/share/applications/` and run `kbuildsycoca6`
(KWin didn't see it until the cache was rebuilt). IPC for testing: `dock preview <desktop-id>` / `dock preview ""`.
Gotchas: Quickshell only detects `pragma Singleton` on its own line near the top (DockApps); a singleton literally
named `Dock` also failed - kept as `DockApps`.
