# The login (v2 stage 4)

One user, no choices. The SDDM theme (`/usr/share/sddm/themes/clockmost`) shows a loading screen while it asks the
tang servers on the home LAN (`theme.conf` `tangUrls`, any one will do) every half second. When tang answers, it logs in with an empty
password, and the **tang gate** (`/usr/lib/clockmost-shell/tang-gate`, run by `pam_exec`) checks it for real: it
passes only if the password is empty, it's the first such login this boot, and tang unlocks the sealed file
`/etc/clockmost/tang-gate.jwe`. No tang within `cutoff` seconds, or the gate says no: the password field.

The gate proves "this PC is on the home LAN", not "this is the user". The lock screen's PAM (`/etc/pam.d/kde`) is untouched by
the package.

## Wiring (by hand, per machine)

Sealed file (random content - the proof is that a tang can unlock it; `sss` with `t: 1` = any one of them):

    sudo install -d -m 755 /etc/clockmost
    head -c 32 /dev/urandom | base64 | sudo sh -c 'umask 077; clevis encrypt sss "{\"t\":1,\"pins\":{\"tang\":[{\"url\":\"http://TANG1\"},{\"url\":\"http://TANG2\"}]}}" -y > /etc/clockmost/tang-gate.jwe'

`/etc/pam.d/sddm`, first two auth lines (only `USER` gets the gate; anything else falls through to the password):

    auth  [success=1 default=ignore]     pam_succeed_if.so quiet user notin USER
    auth  [success=done default=ignore]  pam_exec.so quiet expose_authtok /usr/lib/clockmost-shell/tang-gate

`/etc/sddm.conf.d/10-theme.conf`: `[Theme] Current=clockmost`.

Test the theme without logging out: `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/clockmost`.
Gate log: `journalctl -t tang-gate`.

## The lock screen

`lockscreen/` = the Plasma/Shell package `org.clockmost.lock` (`/usr/share/plasma/shells/org.clockmost.lock`), only a
`contents/lockscreen/LockScreen.qml`: the login's pieces and motion, quicker. KDE's lock program
(`kscreenlocker_greet`, started by KWin) loads the lock screen from the shell package named by `PLASMA_DEFAULT_SHELL`
in KWin's environment; `clockmost-desktop-setup` (setup.d/30) puts that in a drop-in on `plasma-kwin_wayland.service`,
so plasmashell keeps `org.kde.plasma.desktop`. From the next login. Off: a line `lock` in
`~/.config/clockmost/setup-off`, then `clockmost-desktop-setup`.

It talks to PAM through `authenticator`: the field's password goes in with `respond()` to the interactive stack
(`kde`); a success from any stack arrives as `onSucceeded`. The window activates itself (without that, a real lock
gets no typing - `--testing` hides it). Never `stopAuthenticating()` + `startAuthenticating()` to restart PAM: stopping
kills the worker and it doesn't come back ("Not connected to D-Bus server").

### A YubiKey on the lock screen (by hand, per machine - Brigid has it)

KDE runs a second, background check next to the password: the "fingerprint" stack (`kde-fingerprint`), retried for as
long as the screen is locked. The key goes there, so it can be plugged in at any time and a touch unlocks. KDE drops
that check for good after a few instant failures, so `/usr/lib/clockmost-shell/wait-fido-key` first waits (quietly)
until a key is plugged in. Needs `pam-u2f` and a mapping file (`pamu2fcfg -o pam://clockmost -i pam://clockmost`).

`/etc/pam.d/kde-fingerprint` (shadows `/usr/lib/pam.d/kde-fingerprint`; fail-closed - only a registered key's touch passes):

    auth       requisite                      pam_exec.so quiet /usr/lib/clockmost-shell/wait-fido-key
    auth       [success=done default=ignore]  pam_u2f.so  authfile=/etc/u2f_mappings origin=pam://clockmost appid=pam://clockmost cue pinverification=0
    auth       required                       pam_deny.so
    account    include                        system-local-login
    password   required                       pam_deny.so
    session    include                        system-local-login

`/etc/pam.d/kde` = the password only (no `pam_u2f`: two stacks opening the key at once fight over it) - Arch's
`system-auth` auth lines (faillock preauth, pam_unix, faillock authfail/authsucc), then `system-local-login` for
account/password/session. Watch it: `QT_LOGGING_RULES="*.debug=true" /usr/lib/kscreenlocker_greet --testing --shell
org.clockmost.lock` and `journalctl -t kscreenlocker_worker`.

Test without locking (a window; unlocking for real quits it): `/usr/lib/kscreenlocker_greet --testing --shell
org.clockmost.lock`.
