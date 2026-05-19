# Building And Packaging

Cypher OS is Arduino CLI only and targets the M5Stack Cardputer ADV.

## Build The Launcher

From the repo root:

```bash
arduino-cli compile --profile adv .
```

Or use the helper:

```bash
./tools/build-launcher.sh
```

The canonical launcher profile is defined in `sketch.yaml`:

```text
m5stack:esp32:m5stack_cardputer:FlashSize=8M,PartitionScheme=custom,CDCOnBoot=cdc,USBMode=hwcdc
```

## Flash The Launcher

List boards first:

```bash
arduino-cli board list
```

Then flash with the local helper:

```bash
./tools/flash-launcher.sh /dev/cu.usbmodemXXXX
```

If the port is omitted, the script tries the first `/dev/cu.usbmodem*` port it
finds. It touches the port at 1200 baud, waits briefly for re-enumeration, then
uploads with the `adv` profile.

## Build App Binaries

Build all public app targets:

```bash
./tools/build-apps.sh
```

Build one primary app while developing:

```bash
./tools/build-apps.sh --app cypher-chat
./tools/build-apps.sh --app esp32-pokedex
./tools/build-apps.sh --app cypher-desk
```

Build imported Cardputer Game OS titles:

```bash
./tools/build-apps.sh --app cardputer-game-os-games
```

App binaries and generated manifest output are written under:

```text
dist/apps/
dist/BUILD_REPORT.md
```

## Package The SD Card

After building app binaries:

```bash
./tools/package-sd.sh
```

This prepares:

```text
dist/sd-card/
```

Copy the contents of `dist/sd-card` to the root of a FAT32 SD card.

Expected packaged layout:

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
/cypher-puter/apps/esp32-pokedex.bin
/cypher-puter/apps/flock-you.bin
/cypher-puter/apps/wiretap-32-cardputer.bin
/cypher-puter/apps/<cardputer-game-os-game>.bin
/cardputer-mpc/
/cypher-drive/payloads/
/cardputer-game-os/saves/
```

## Workspace Layout

By default, scripts look for sibling repos beside this checkout:

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
  esp32-pokedex/
  cypher-desk/
  flock-you/
  WireTap-32/
```

Set a different workspace root:

```bash
CYPHER_OS_WORKSPACE_ROOT=/path/to/repos ./tools/build-apps.sh
```

Or override individual app repos:

```bash
CYPHER_OS_CARDPUTER_GAMES_DIR=/path/to/cardputer-games ./tools/build-apps.sh
CYPHER_OS_CARDPUTER_MPC_DIR=/path/to/cardputer-mpc ./tools/build-apps.sh
CYPHER_OS_CARDPUTER_TAROT_DIR=/path/to/cardputer-tarot ./tools/build-apps.sh
CYPHER_OS_CYPHER_PN532_DIR=/path/to/cypher-pn532 ./tools/build-apps.sh
CYPHER_OS_CYPHER_CHAT_DIR=/path/to/cypher-chat/cypher-chat-firmware ./tools/build-apps.sh
CYPHER_OS_CYPHER_DRIVE_DIR=/path/to/cypher-drive ./tools/build-apps.sh
CYPHER_OS_ESP32_BT_HID_DIR=/path/to/ESP32_BT_HID ./tools/build-apps.sh
CYPHER_OS_ESP32_POKEDEX_DIR=/path/to/esp32-pokedex ./tools/build-apps.sh
CYPHER_OS_CYPHER_DESK_DIR=/path/to/cypher-desk ./tools/build-apps.sh
CYPHER_OS_FLOCK_YOU_DIR=/path/to/flock-you ./tools/build-apps.sh
CYPHER_OS_WIRETAP_DIR=/path/to/WireTap-32 ./tools/build-apps.sh
CYPHER_OS_GAME_OS_DIR=/path/to/cardputer-game-os ./tools/build-apps.sh
```

`./tools/package-sd.sh` also uses the workspace root and relevant per-app
overrides when copying SD asset folders.

## Release Package

Prepare the same artifact set used by official releases:

```bash
./tools/prepare-release.sh v0.1.0
```

Release assets are:

```text
cypher-os-launcher.bin
cypher-os-sd-card.zip
apps.json
BUILD_REPORT.md
```

Generated manifests are derived output. Update `config/apps.json`, rebuild, and
let the tools regenerate `dist/`.
