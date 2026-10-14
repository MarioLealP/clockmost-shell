//! clockmost-autoscroll: Windows-style middle-button autoscroll for every app (Mario 2026-10-14; Linux has none).
//!
//! Each mouse is grabbed and re-emitted through a virtual twin, untouched - except the middle button:
//!   - middle click (no movement)    -> Windows' click-to-toggle (Mario): autoscroll until the next click of any
//!     button (that click is swallowed, as on Windows). Except over apps with their own autoscroll (Firefox, the
//!     phonograph): there the click passes through. The shell decides - see the socket protocol below.
//!   - middle held + moved past 8 px -> autoscroll while held; release stops it
//!
//! Scrolling = hi-res wheel events, faster the further the pointer is from the anchor, both axes.
//!
//! Runs as a system service under its own user (input group: mice only are grabbed; the desktop user stays out of
//! `input`, which can read keyboards). The shell connects to the unix socket /run/clockmost-autoscroll/events:
//! it gets `start`, `dir <-1|0|1> <-1|0|1>`, `stop` (it draws the anchor marker), and on a plain middle click
//! `query <n>` - it answers `toggle <n>` (autoscroll here) or `pass <n>` (hand the click to the app) within
//! QUERY_WAIT, else the click passes. The number keeps a late answer from being read as the next one's.
//! The shell may also send `paste`: the service presses Ctrl+V on its own virtual keyboard, which can type nothing
//! else (Win+V clipboard history pastes what you pick, as on Windows - Wayland gives a normal client no way to).

use std::io::{BufRead, Write};
use std::os::unix::net::{UnixListener, UnixStream};
use std::path::Path;
use std::sync::{Arc, Condvar, Mutex};
use std::time::{Duration, Instant};

use anyhow::{Context, Result};
use evdev::uinput::VirtualDevice;
use evdev::{AbsoluteAxisCode, AttributeSet, Device, EventType, InputEvent, KeyCode, RelativeAxisCode};

const NAME: &str = "clockmost-autoscroll";
const SOCKET: &str = "/run/clockmost-autoscroll/events";
const START_PX: f64 = 8.0; // movement that turns a middle press into autoscroll
const DEAD_PX: f64 = 12.0; // no scrolling this close to the anchor
const TICK: Duration = Duration::from_millis(8);
/// absolute pointers (VMs, tablets) report 0..max per axis; treat the range as this many pixels
const ABS_SPAN_PX: f64 = 1920.0;

const QUERY_WAIT: Duration = Duration::from_millis(250);
const PASTE_GAP: Duration = Duration::from_millis(300); // a flood of `paste` presses Ctrl+V at most this often
static QUERY: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);

/// the shell's end of the socket: the connections to tell things, and the latest `toggle|pass <n>` answer
#[derive(Default)]
struct Shell {
    streams: Mutex<Vec<UnixStream>>,
    answer: Mutex<Option<(u64, bool)>>,
    answered: Condvar,
}

type Listeners = Arc<Shell>;

/// ask the shell whether a plain middle click should toggle autoscroll here (false = pass the click on)
fn ask_toggle(shell: &Shell) -> bool {
    let n = QUERY.fetch_add(1, std::sync::atomic::Ordering::Relaxed) + 1;
    let deadline = Instant::now() + QUERY_WAIT;
    if notify(shell, &format!("query {n}")) == 0 {
        return false;
    }
    let mut answer = shell.answer.lock().expect("answer lock");
    loop {
        if let Some((id, toggle)) = *answer
            && id == n
        {
            return toggle;
        } // none yet, or an older answer
        let left = deadline.saturating_duration_since(Instant::now());
        if left.is_zero() {
            return false;
        }
        answer = shell.answered.wait_timeout(answer, left).expect("answer lock").0;
    }
}

/// tells every connected shell; returns how many are still connected
fn notify(shell: &Shell, line: &str) -> usize {
    let mut list = shell.streams.lock().expect("streams lock");
    list.retain_mut(|s| s.write_all(line.as_bytes()).and_then(|()| s.write_all(b"\n")).is_ok());
    list.len()
}

/// one shell connection's lines: answers to queries, and `paste`
fn read_shell(stream: UnixStream, shell: &Shell, keyboard: &Mutex<VirtualDevice>) {
    let mut last_paste: Option<Instant> = None;
    for line in std::io::BufReader::new(stream).lines() {
        let Ok(line) = line else { break };
        let mut it = line.split_whitespace();
        match (it.next(), it.next().and_then(|x| x.parse::<u64>().ok())) {
            (Some(verb @ ("toggle" | "pass")), Some(n)) => {
                *shell.answer.lock().expect("answer lock") = Some((n, verb == "toggle"));
                shell.answered.notify_all();
            }
            (Some("paste"), _) if last_paste.is_none_or(|t| t.elapsed() >= PASTE_GAP) => {
                last_paste = Some(Instant::now());
                if let Err(e) = press_ctrl_v(&mut keyboard.lock().expect("keyboard lock")) {
                    eprintln!("{NAME}: paste: {e:#}");
                }
            }
            _ => {}
        }
    }
}

/// the paste keyboard: Ctrl and V, nothing else
fn paste_keyboard() -> Result<VirtualDevice> {
    let mut keys = AttributeSet::<KeyCode>::new();
    keys.insert(KeyCode::KEY_LEFTCTRL);
    keys.insert(KeyCode::KEY_V);
    Ok(VirtualDevice::builder()?.name(&format!("{NAME} paste")).with_keys(&keys)?.build()?)
}

fn press_ctrl_v(kb: &mut VirtualDevice) -> Result<()> {
    let key = |k: KeyCode, v| InputEvent::new(EventType::KEY.0, k.0, v);
    // a beat between steps: some clients miss a modifier that arrives in the same frame as the key
    for step in [key(KeyCode::KEY_LEFTCTRL, 1), key(KeyCode::KEY_V, 1), key(KeyCode::KEY_V, 0), key(KeyCode::KEY_LEFTCTRL, 0)] {
        kb.emit(&[step])?;
        std::thread::sleep(Duration::from_millis(12));
    }
    Ok(())
}

#[derive(Default)]
struct State {
    pressed: bool,
    toggled: bool, // click-to-toggle mode: runs until the next click
    swallow: Vec<KeyCode>, // the stopping click's buttons - their releases are swallowed too
    scrolling: bool,
    dx: f64, // pointer offset from the anchor, px
    dy: f64,
    abs: (Option<i32>, Option<i32>), // last absolute position (absolute devices)
    anchor_abs: (Option<i32>, Option<i32>),
    carry_v: f64, // hi-res wheel units not yet emitted
    carry_h: f64,
    notch_v: i32, // hi-res units since the last legacy wheel notch
    notch_h: i32,
    dir: (i32, i32),
}

/// px per second -> grows faster than the distance: fine near the anchor, fast far away
fn speed(d: f64) -> f64 {
    let a = d.abs() - DEAD_PX;
    if a <= 0.0 { 0.0 } else { d.signum() * a.powf(1.35) * 4.0 }
}

fn twin(dev: &Device) -> Result<VirtualDevice> {
    let mut keys = AttributeSet::<KeyCode>::new();
    for k in dev.supported_keys().map(|k| k.iter().collect::<Vec<_>>()).unwrap_or_default() {
        keys.insert(k);
    }
    let mut rels = AttributeSet::<RelativeAxisCode>::new();
    for r in dev.supported_relative_axes().map(|r| r.iter().collect::<Vec<_>>()).unwrap_or_default() {
        rels.insert(r);
    }
    for r in [RelativeAxisCode::REL_WHEEL, RelativeAxisCode::REL_HWHEEL, RelativeAxisCode::REL_WHEEL_HI_RES,
        RelativeAxisCode::REL_HWHEEL_HI_RES] {
        rels.insert(r);
    }
    let name = format!("{NAME} {}", dev.name().unwrap_or("mouse"));
    let mut b = VirtualDevice::builder()?.name(&name).with_keys(&keys)?.with_relative_axes(&rels)?;
    if let Ok(absinfo) = dev.get_absinfo() {
        for (code, info) in absinfo {
            b = b.with_absolute_axis(&evdev::UinputAbsSetup::new(code, info))?;
        }
    }
    Ok(b.build()?)
}

fn run_device(path: std::path::PathBuf, listeners: Listeners) -> Result<()> {
    let mut dev = Device::open(&path).with_context(|| format!("opening {}", path.display()))?;
    let max = |c: AbsoluteAxisCode| -> f64 {
        dev.get_absinfo().ok().and_then(|mut it| it.find(|(k, _)| *k == c).map(|(_, i)| i.maximum() as f64)).unwrap_or(0.0)
    };
    let (max_x, max_y) = (max(AbsoluteAxisCode::ABS_X), max(AbsoluteAxisCode::ABS_Y));
    let out = Arc::new(Mutex::new(twin(&dev)?));
    dev.grab().context("grabbing")?;
    eprintln!("{NAME}: {} ({})", dev.name().unwrap_or("?"), path.display());
    let st = Arc::new(Mutex::new(State::default()));

    // the scroll clock: while scrolling, turn the offset into wheel events
    {
        let (st, out, listeners) = (st.clone(), out.clone(), listeners.clone());
        std::thread::spawn(move || {
            let mut last = Instant::now();
            loop {
                std::thread::sleep(TICK);
                let dt = last.elapsed().as_secs_f64();
                last = Instant::now();
                let mut s = st.lock().expect("state lock");
                if !s.scrolling {
                    continue;
                }
                let dir = (
                    if s.dx.abs() > DEAD_PX { s.dx.signum() as i32 } else { 0 },
                    if s.dy.abs() > DEAD_PX { s.dy.signum() as i32 } else { 0 },
                );
                if dir != s.dir {
                    s.dir = dir;
                    notify(&listeners, &format!("dir {} {}", dir.0, dir.1));
                }
                // wheel: 120 hi-res units = one notch = ~ 50 px of scrolling in most apps
                s.carry_v -= speed(s.dy) * dt * 120.0 / 50.0; // pointer below the anchor = scroll down = negative
                s.carry_h += speed(s.dx) * dt * 120.0 / 50.0;
                let (v, h) = (s.carry_v.trunc() as i32, s.carry_h.trunc() as i32);
                s.carry_v -= v as f64;
                s.carry_h -= h as f64;
                let mut evs = Vec::new();
                if v != 0 {
                    evs.push(InputEvent::new(EventType::RELATIVE.0, RelativeAxisCode::REL_WHEEL_HI_RES.0, v));
                    s.notch_v += v;
                    let n = s.notch_v / 120;
                    if n != 0 {
                        s.notch_v -= n * 120;
                        evs.push(InputEvent::new(EventType::RELATIVE.0, RelativeAxisCode::REL_WHEEL.0, n));
                    }
                }
                if h != 0 {
                    evs.push(InputEvent::new(EventType::RELATIVE.0, RelativeAxisCode::REL_HWHEEL_HI_RES.0, h));
                    s.notch_h += h;
                    let n = s.notch_h / 120;
                    if n != 0 {
                        s.notch_h -= n * 120;
                        evs.push(InputEvent::new(EventType::RELATIVE.0, RelativeAxisCode::REL_HWHEEL.0, n));
                    }
                }
                if !evs.is_empty() {
                    let _ = out.lock().expect("out lock").emit(&evs);
                }
            }
        });
    }

    loop {
        let events: Vec<InputEvent> = dev.fetch_events().context("reading")?.collect();
        let mut pass = Vec::with_capacity(events.len());
        let mut s = st.lock().expect("state lock");
        let st = &st;
        for ev in events {
            match ev.destructure() {
                // toggle mode: the next press of any button stops it and is swallowed with its release
                evdev::EventSummary::Key(_, k, 1) if s.toggled && is_button(k) => {
                    notify(&listeners, "stop");
                    let abs = s.abs;
                    *s = State { abs, swallow: vec![k], ..State::default() };
                    continue;
                }
                evdev::EventSummary::Key(_, k, 0) if s.swallow.contains(&k) => {
                    s.swallow.retain(|x| *x != k);
                    continue;
                }
                evdev::EventSummary::Key(_, KeyCode::BTN_MIDDLE, value) => {
                    if value == 1 {
                        *s = State { pressed: true, anchor_abs: s.abs, abs: s.abs, ..State::default() };
                    } else if value == 0 && s.pressed {
                        if s.scrolling {
                            notify(&listeners, "stop"); // held + dragged: release ends it
                            let abs = s.abs;
                            *s = State { abs, ..State::default() };
                        } else {
                            // a plain click: toggle autoscroll here, or hand it to the app (the shell decides)
                            drop(s);
                            let toggle = ask_toggle(&listeners);
                            s = st.lock().expect("state lock");
                            let abs = s.abs;
                            if toggle {
                                *s = State { pressed: true, toggled: true, scrolling: true, abs, anchor_abs: abs, ..State::default() };
                                notify(&listeners, "start");
                            } else {
                                pass.push(InputEvent::new(EventType::KEY.0, KeyCode::BTN_MIDDLE.0, 1));
                                pass.push(InputEvent::new(EventType::SYNCHRONIZATION.0, 0, 0));
                                pass.push(InputEvent::new(EventType::KEY.0, KeyCode::BTN_MIDDLE.0, 0));
                                *s = State { abs, ..State::default() };
                            }
                        }
                    }
                    continue; // the original middle events never pass
                }
                evdev::EventSummary::RelativeAxis(_, RelativeAxisCode::REL_X, v) if s.pressed => s.dx += v as f64,
                evdev::EventSummary::RelativeAxis(_, RelativeAxisCode::REL_Y, v) if s.pressed => s.dy += v as f64,
                evdev::EventSummary::AbsoluteAxis(_, AbsoluteAxisCode::ABS_X, v) => {
                    s.abs.0 = Some(v);
                    if let (true, Some(a), true) = (s.pressed, s.anchor_abs.0, max_x > 0.0) {
                        s.dx = (v - a) as f64 / max_x * ABS_SPAN_PX;
                    }
                }
                evdev::EventSummary::AbsoluteAxis(_, AbsoluteAxisCode::ABS_Y, v) => {
                    s.abs.1 = Some(v);
                    if let (true, Some(a), true) = (s.pressed, s.anchor_abs.1, max_y > 0.0) {
                        s.dy = (v - a) as f64 / max_y * ABS_SPAN_PX * (max_x / max_y.max(1.0)).min(1.0);
                    }
                }
                _ => {}
            }
            if s.pressed && !s.scrolling && (s.dx.abs() > START_PX || s.dy.abs() > START_PX) {
                s.scrolling = true;
                notify(&listeners, "start");
            }
            pass.push(ev);
        }
        drop(s);
        if !pass.is_empty() {
            out.lock().expect("out lock").emit(&pass).context("emitting")?;
        }
    }
}

fn is_button(k: KeyCode) -> bool {
    (KeyCode::BTN_LEFT.0..=KeyCode::BTN_TASK.0).contains(&k.0)
}

/// a mouse: has a middle button and moves; not a virtual device (ours, ydotool, VM drag-and-drop helpers)
fn is_mouse(dev: &Device) -> bool {
    let name = dev.name().unwrap_or("");
    let virt = name.starts_with(NAME) || name.contains("ydotool") || name.contains("DnD UInput");
    let middle = dev.supported_keys().is_some_and(|k| k.contains(KeyCode::BTN_MIDDLE));
    let moves = dev.supported_relative_axes().is_some_and(|r| r.contains(RelativeAxisCode::REL_X))
        || dev.supported_absolute_axes().is_some_and(|a| a.contains(AbsoluteAxisCode::ABS_X));
    let keyboard = dev.supported_keys().is_some_and(|k| k.contains(KeyCode::KEY_A));
    !virt && middle && moves && !keyboard
}

fn main() -> Result<()> {
    let listeners: Listeners = Arc::default();
    let keyboard = Arc::new(Mutex::new(paste_keyboard().context("creating the paste keyboard")?));
    {
        let _ = std::fs::remove_file(SOCKET);
        let listener = UnixListener::bind(SOCKET).with_context(|| format!("binding {SOCKET}"))?;
        // the desktop user's shell connects; the directory (RuntimeDirectory) is what limits who can reach it
        std::fs::set_permissions(SOCKET, std::os::unix::fs::PermissionsExt::from_mode(0o666))?;
        let listeners = listeners.clone();
        std::thread::spawn(move || {
            for s in listener.incoming().flatten() {
                let (shell, keyboard) = (listeners.clone(), keyboard.clone());
                if let Ok(r) = s.try_clone() {
                    std::thread::spawn(move || read_shell(r, &shell, &keyboard));
                }
                listeners.streams.lock().expect("streams lock").push(s);
            }
        });
    }
    // hotplug: look for new mice every 2s
    let mut taken: Vec<std::path::PathBuf> = Vec::new();
    loop {
        for (path, dev) in evdev::enumerate() {
            if taken.contains(&path) || !is_mouse(&dev) {
                continue;
            }
            taken.push(path.clone());
            let listeners = listeners.clone();
            std::thread::spawn(move || {
                if let Err(e) = run_device(path.clone(), listeners) {
                    eprintln!("{NAME}: {}: {e:#}", path.display());
                }
            });
        }
        taken.retain(|p| Path::new(p).exists());
        std::thread::sleep(Duration::from_secs(2));
    }
}
