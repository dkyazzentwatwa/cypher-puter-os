# Cypher OS

**A local-first app deck for the [M5Stack Cardputer ADV][cardputer-affiliate].**

Cypher OS turns the [M5Stack Cardputer ADV][cardputer-affiliate] into a pocket-sized launcher for real
Cardputer apps. Flash the launcher once, build a local SD catalog, then swap
between tools, games, music, chat, storage, and field utilities without doing a
USB reflash every time you want to change what the device does.

It feels like a tiny handheld OS, but it stays honest about the hardware:
ESP32 apps do not execute directly from SD. Cypher OS keeps a small launcher in
the primary app slot, installs the selected app `.bin` from the SD catalog into
the app partition, then reboots into that app. When the app supports return,
you come back to the launcher and pick the next thing.

## Why It Rules

- **One Cardputer, many personalities.** Carry a launcher, groovebox, secure
  chat tool, offline desk kit, arcade catalog, tarot journal, detector build,
  and bench utility on one SD card.
- **No cloud catalog. No online dependency.** The whole flow is local: build
  apps, package the SD card, boot the launcher, pick what you want.
- **Made for repeat use.** Apps can return to Cypher OS instead of turning the
  workflow into flash-once-and-done firmware.
- **Small launcher, big catalog.** The launcher stays focused on browsing,
  installing, launching, and recovering from the SD app catalog.
- **Arduino CLI only.** The repo is intentionally simple and scriptable for
  local builds.
- **Purpose-built for [Cardputer ADV][cardputer-affiliate].** No generic board matrix, no stretched
  scope, no pretending this is a multi-platform firmware framework.

## Current App Lineup

These are the supported Cardputer app targets in the current catalog flow:

| App | What It Adds |
| --- | --- |
| **[Cypher Drive][cypher-drive-repo]** | [Cardputer ADV][cardputer-affiliate] HID payload launcher build. |
| **[ESP32 BT HID][esp32-bt-hid-repo]** | BLE-HID payload deck with SD-backed DuckyScript payloads and a Wi-Fi editor. |
| **[Cypher Chat][cypher-chat-repo]** | Secure-only mesh chat build using protocol `0x02` with AES-256-GCM. |
| **[Cardputer Games][cardputer-games-repo]** | Standalone Cardputer arcade catalog. |
| **[Cardputer MPC][cardputer-mpc-repo]** | MPC-style groovebox with SD-loaded samples and sequencing. |
| **[Cardputer Tarot][cardputer-tarot-repo]** | Offline tarot pull, journal, history, and study deck app. |
| **[Cypher PN532][cypher-pn532-repo]** | PN532 NFC toolkit for the [Cardputer ADV][cardputer-affiliate] EXT I2C header. |
| **Cypher Desk** | Offline utility suite with notes, calculator, checklist, converters, and scratchpad. |
| **[Flock You][cypher-flock-repo]** | [Cardputer ADV][cardputer-affiliate] WiFi/BLE detector build with return-to-launcher support. |
| **[WireTap-32 Cardputer][wiretap-32-repo]** | [Cardputer ADV][cardputer-affiliate] EXT bench build with return-to-launcher support. |
| **[Cardputer Game OS games][cardputer-game-os-repo]** | Individual game `.bin` files imported from the sibling `cardputer-game-os` repo when present and built successfully. |

`starbeam_v2` is not part of the Cypher OS app catalog.

## App Docs

For deeper notes on each app, controls, SD paths, return behavior, and imported
game manuals, see [docs/README.md](docs/README.md).

## How Launching Works

Cypher OS uses a compact local OTA-slot model:

- The launcher lives in `ota_0`.
- SD app binaries live under `/cypher-puter/apps`.
- Choosing an app copies that app `.bin` into `ota_1`.
- The device restarts into the installed app.
- Supported apps can set a one-shot return flag and restart back to the
  launcher menu.

Use sketch app `.bin` files, not merged flash images. The launcher checks for
oversized binaries and rejects merged images before writing.

## Hardware

- [M5Stack Cardputer ADV][cardputer-affiliate]
- FAT32 SD card, preferably 32 GB or smaller
- Apps stored under `/cypher-puter/apps`

## Responsible Use

Cypher OS is for local, authorized hardware, NFC, wireless, and embedded-device
work. Use the apps only with devices, cards, networks, and systems you own or
have clear permission to test. The SD catalog is intentionally local-first and
does not include an online payload or OTA feed.

## Build And Flash The Launcher

Build with the [Cardputer ADV][cardputer-affiliate] profile:

```bash
cd cypher-puter-os
arduino-cli compile --profile adv .
```

Or use the helper:

```bash
./tools/build-launcher.sh
```

The canonical profile is in `sketch.yaml`:

```text
m5stack:esp32:m5stack_cardputer:FlashSize=8M,PartitionScheme=custom,CDCOnBoot=cdc,USBMode=hwcdc
```

Flash with the local helper:

```bash
arduino-cli board list
./tools/flash-launcher.sh /dev/cu.usbmodemXXXX
```

If you omit the port, the script uses the first `/dev/cu.usbmodem*` port it
finds, touches it at 1200 baud, waits for re-enumeration, then uploads with the
`adv` profile.

## Build And Package SD Apps

Build the app binaries and package the SD card folder:

```bash
./tools/build-apps.sh
./tools/package-sd.sh
```

Then copy the contents of:

```text
dist/sd-card
```

to the root of a FAT32 SD card.

Expected SD layout:

```text
/cypher-puter/apps/apps.json
/cypher-puter/apps/cardputer-games.bin
/cypher-puter/apps/cardputer-mpc.bin
/cypher-puter/apps/cardputer-tarot.bin
/cypher-puter/apps/cypher-pn532.bin
/cypher-puter/apps/cypher-desk.bin
/cypher-puter/apps/cypher-chat.bin
/cypher-puter/apps/cypher-drive.bin
/cypher-puter/apps/esp32-bt-hid.bin
/cypher-puter/apps/flock-you.bin
/cypher-puter/apps/wiretap-32-cardputer.bin
/cypher-puter/apps/<cardputer-game-os-game>.bin
/cardputer-mpc/
/cypher-drive/payloads/
/cardputer-game-os/saves/
```

The catalog imports individual game `.bin` files from the sibling
`cardputer-game-os` repo. The nested Game OS launcher itself is not packaged
because Cypher OS already owns the launcher partition.

Cypher Chat is built from the sibling `cypher-chat/cypher-chat-firmware` sketch
with `BOARD_PROFILE_CARDPUTER_ADV`. Its mesh protocol is secure-only `0x02`, so
all fleet devices need matching firmware.

## Workspace Layout

The app scripts default to sibling repos beside this checkout:

Source repositories: [Cardputer MPC][cardputer-mpc-repo],
[Cypher Chat][cypher-chat-repo], [Cardputer Games][cardputer-games-repo],
[Cypher Drive][cypher-drive-repo], [Cardputer Tarot][cardputer-tarot-repo],
[ESP32 BT HID][esp32-bt-hid-repo], [Cypher PN532][cypher-pn532-repo], [Cypher Flock][cypher-flock-repo],
[WireTap-32][wiretap-32-repo], and
[Cardputer Game OS][cardputer-game-os-repo].

```text
GitHub/
  cypher-puter-os/
  cardputer-games/
  cardputer-mpc/
  cardputer-tarot/
  cypher-pn532/
  cardputer-game-os/
  cypher-chat/
  cypher-drive/
  ESP32_BT_HID/
  cypher-desk/
  flock-you/
  WireTap-32/
```

For a different layout, set a workspace root:

```bash
CYPHER_OS_WORKSPACE_ROOT=/path/to/repos ./tools/build-apps.sh
```

You can also override individual app paths:

```bash
CYPHER_OS_CARDPUTER_MPC_DIR=/path/to/cardputer-mpc ./tools/package-sd.sh
CYPHER_OS_CARDPUTER_TAROT_DIR=/path/to/cardputer-tarot ./tools/build-apps.sh
CYPHER_OS_CYPHER_PN532_DIR=/path/to/cypher-pn532 ./tools/build-apps.sh
CYPHER_OS_ESP32_BT_HID_DIR=/path/to/ESP32_BT_HID ./tools/build-apps.sh
```

## Controls

- `,` or `;`: up
- `.` or `/`: down
- `W/S` and `K/J`: up/down alternatives
- `Enter` or BtnA: select
- Backtick, `Del`, `Tab`, or `Q`: back
- `R`: reload SD catalog
- The launcher plays short procedural cues for movement, select, back, toggles,
  and warnings. Use Settings -> Sound effects to turn them on or off.
- Settings includes Boot behavior, Brightness, Sound effects, and Reload SD
  catalog.
- In packaged apps, use the app's **Return to Launcher** item or `Del/Q` where
  shown. The app restarts, sets a one-shot return flag, and the launcher stays
  on the menu instead of auto-launching again.
- Cardputer MPC: use `Shift+Q` to return to Cypher OS. Lowercase `q` remains an
  MPC pad trigger.
- Cypher PN532: use the `Return to Cypher OS` main-menu item or press
  `Del`, `Tab`, backtick, or `Q` from the main menu.
- ESP32 BT HID: press backtick, `Esc`, or `Del` from the top-level device list
  to return to Cypher OS.
- Flock You: open the mini menu, cycle to `HOME`, then press up/down to return.
- WireTap-32: choose `Launcher` from the main menu, or type `launcher` /
  `return` over serial.

## Serial Commands

```text
help
status
apps
reload
launch
erase
install <slug>
```

## Technical Notes

- This repo is Arduino CLI only.
- Target hardware is the [M5Stack Cardputer ADV][cardputer-affiliate].
- The supported launch model is local SD catalog install into the app
  partition, then reboot.
- Keep the launcher small and local: no online OTA catalog, WebUI, USB mass
  storage, multi-board ports, PlatformIO, or ESP-IDF project files.
- The shared data partition is LittleFS so Cypher Drive can mount its log/config
  storage when launched from this OS.
- `Boot behavior` can auto-try the installed app on power-up or always stop at
  the launcher menu.
- Cypher PN532 expects a PN532 module in I2C mode on the [Cardputer ADV][cardputer-affiliate] EXT
  header: VCC to pin 6 `5VOUT`, GND to pin 4 `GND`, SDA to pin 8 `G8`, and SCL
  to pin 10 `G9`; leave PN532 RESET, INT, and BUSY unconnected for this build.

[cardputer-affiliate]: https://amzn.to/4dqii8h
[cardputer-game-os-repo]: https://github.com/dkyazzentwatwa/cardputer-game-os
[cardputer-games-repo]: https://github.com/dkyazzentwatwa/cardputer-games
[cardputer-mpc-repo]: https://github.com/dkyazzentwatwa/cardputer-mpc
[cardputer-tarot-repo]: https://github.com/dkyazzentwatwa/cardputer-tarot
[cypher-chat-repo]: https://github.com/dkyazzentwatwa/cypher-chat
[cypher-drive-repo]: https://github.com/dkyazzentwatwa/cypher-drive
[cypher-flock-repo]: https://github.com/dkyazzentwatwa/cypher-flock
[cypher-pn532-repo]: https://github.com/dkyazzentwatwa/cypher-pn532
[esp32-bt-hid-repo]: https://github.com/dkyazzentwatwa/ESP32_BT_HID
[wiretap-32-repo]: https://github.com/dkyazzentwatwa/WireTap-32
