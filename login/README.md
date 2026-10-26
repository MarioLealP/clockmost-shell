# The login (v2 stage 4)

One user, no choices. The SDDM theme (`/usr/share/sddm/themes/clockmost`) shows a loading screen while it asks the
tang server on the home LAN (`theme.conf` `tangUrl`) every half second. When tang answers, it logs in with an empty
password, and the **tang gate** (`/usr/lib/clockmost-shell/tang-gate`, run by `pam_exec`) checks it for real: it
passes only if the password is empty, it's the first such login this boot, and tang unlocks the sealed file
`/etc/clockmost/tang-gate.jwe`. No tang within `cutoff` seconds, or the gate says no: the password field.

The gate proves "this PC is on the home LAN", not "this is the user". The lock screen (`/etc/pam.d/kde`) is untouched.

## Wiring (by hand, per machine)

Sealed file (random content - the proof is that tang can unlock it):

    sudo install -d -m 755 /etc/clockmost
    head -c 32 /dev/urandom | base64 | sudo sh -c 'umask 077; clevis encrypt tang "{\"url\":\"http://TANG:7654\"}" -y > /etc/clockmost/tang-gate.jwe'

`/etc/pam.d/sddm`, first two auth lines (only `USER` gets the gate; anything else falls through to the password):

    auth  [success=1 default=ignore]     pam_succeed_if.so quiet user notin USER
    auth  [success=done default=ignore]  pam_exec.so quiet expose_authtok /usr/lib/clockmost-shell/tang-gate

`/etc/sddm.conf.d/10-theme.conf`: `[Theme] Current=clockmost`.

Test the theme without logging out: `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/clockmost`.
Gate log: `journalctl -t tang-gate`.
