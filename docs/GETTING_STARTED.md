# Getting Started

This guide is for a new Cypher OS user with a M5Stack Cardputer ADV, a FAT32 SD
card, and a public release bundle.

## What You Need

- M5Stack Cardputer ADV.
- FAT32 microSD card, preferably 32 GB or smaller.
- USB-C cable that supports data.
- Release assets from the latest GitHub release:
  - `cypher-os-launcher.bin`
  - `cypher-os-sd-card.zip`
  - `apps.json`
  - `BUILD_REPORT.md`

`apps.json` and `BUILD_REPORT.md` are there so you can inspect the release. The
two files you actually install are the launcher `.bin` and the SD card `.zip`.

## Install Flow

1. Flash `cypher-os-launcher.bin` to the Cardputer ADV.
2. Unzip `cypher-os-sd-card.zip`.
3. Copy the unzipped contents to the root of the FAT32 SD card.
4. Insert the SD card into the Cardputer.
5. Boot the Cardputer.
6. Open the SD App Catalog and choose an app.

The SD card should contain this shape after copying:

```text
/cypher-puter/apps/apps.json
/cypher-puter/apps/*.bin
/cardputer-mpc/
/cypher-drive/
/cardputer-game-os/saves/
```

Some apps use extra data folders. ESP32 Pokedex expects its larger Pokemon data,
sprites, optional audio, and config folders at:

```text
/pokemon/
/audio/
/config/
```

## First Boot

On boot, the launcher checks the SD card and reads:

```text
/cypher-puter/apps/apps.json
```

If the SD card is mounted and the catalog is valid, the launcher shows the app
list. If not, open Diagnostics or read [Troubleshooting](TROUBLESHOOTING.md).

## Launcher Controls

| Action | Keys |
| --- | --- |
| Move up | `,`, `;`, `W`, or `K` |
| Move down | `.`, `/`, `S`, or `J` |
| Select | `Enter` or BtnA |
| Back | Backtick, `Del`, `Tab`, or `Q` |
| Reload SD catalog | `R` |

Settings includes boot behavior, brightness, sound effects, theme, and catalog
reload. Themes are stored in firmware and do not require theme files on the SD
card.

## Choosing An App

Selecting an app copies that app `.bin` from the SD card into the app
partition, then reboots into it. This can take a moment because the launcher is
writing flash.

Use sketch app `.bin` files from the Cypher OS package. Do not use merged flash
images, bootloader images, or partition-table images as app catalog binaries.

## Returning To Cypher OS

Return behavior is app-specific. Common return paths include a `Return to
Cypher OS` menu item, backtick, `Del`, `Q`, or a documented app shortcut.

Important app-specific examples:

- Cardputer MPC uses `Shift+Q`; lowercase `q` is still a pad trigger.
- ESP32 BT HID returns from the top-level device list with backtick, `Esc`, or
  `Del`.
- ESP32 Pokedex has `Return to Cypher OS` on the home menu.
- Cypher PN532 has a `Return to Cypher OS` menu item and also supports `Del`,
  `Tab`, backtick, or `Q` from the main menu.
- Flock You returns through its mini menu `HOME` item.
- WireTap-32 returns through `Launcher` on the main menu or the serial command
  `launcher` / `return`.

For the full list, see [App Catalog](APP_CATALOG.md).
