# plasma-statusbar

A Plasma 6 panel widget (`io.github.aethryl.statusbar`): network, Bluetooth, volume, battery and update glyphs plus the clock. Its notch has Wi-Fi, Bluetooth, sound, brightness, battery, power profiles, session actions and pending updates.

App tray icons stay in KDE's own system tray, placed just left of it with the system items (network, volume, battery, Bluetooth, brightness) turned off in the tray's settings so they aren't shown twice.

## Install

```sh
git clone git@github.com:Aethryl/plasma-statusbar.git
cd plasma-statusbar
./install.sh
gdbus call --session -d org.kde.plasmashell -o /PlasmaShell \
  -m org.kde.PlasmaShell.evaluateScript "$(cat add-to-panel.js)"
```

`install.sh` symlinks `plasmoid/` into `~/.local/share/plasma/plasmoids/`, so edits are live; after a QML change run `systemctl --user restart plasma-plasmashell`.

## Requirements

- Plasma 6 (tested on 6.7.5)

## Licences

The code is MIT, see `LICENSE`.

`plasmoid/contents/images/nordzy/` holds Wi-Fi icons from the [Nordzy icon theme](https://github.com/MolassesLover/Nordzy-icon), GPL-3.0. Its licence text sits next to them in `COPYING`; the icons are not covered by the MIT licence.
