# Troubleshooting

Start with Diagnostics on the launcher. It shows SD mount state, app count,
installed app, app slot size, selected binary size, and the last install error.

## SD Card Missing

Symptoms:

- Launcher says no SD card is mounted.
- Catalog screen says to put apps under `/cypher-puter/apps`.

Check:

- The card is FAT32.
- The card is fully inserted.
- The release SD zip was copied to the root of the card, not nested one folder
  too deep.
- The card contains `/cypher-puter/apps/apps.json`.

Use `R` in the launcher to reload the SD catalog after reinserting or copying
files.

## `apps.json` Missing Or Invalid

The launcher expects:

```text
/cypher-puter/apps/apps.json
```

If you are building locally, run:

```bash
./tools/build-apps.sh
./tools/package-sd.sh
```

Then copy the contents of `dist/sd-card` to the SD root.

Do not hand-edit generated manifests under `dist/`. Update `config/apps.json`
and rebuild instead.

## No Apps Found

If the catalog loads but no apps appear:

- Confirm the release zip was fully extracted.
- Confirm `.bin` files live under `/cypher-puter/apps`.
- Confirm `apps.json` has an `apps` array.
- If building locally, read `dist/BUILD_REPORT.md` for missing or failed app
  builds.

## App Install Fails

Common causes:

- The `.bin` referenced by `apps.json` is missing from `/cypher-puter/apps`.
- The file is a merged image instead of a sketch app binary.
- The binary is too large for the app partition.
- SD read stopped before the binary completed.
- Flash erase or write failed.

Use the Diagnostics screen or serial `status` command to see the last error.

## USB Modem Port Missing

The flash helper expects a `/dev/cu.usbmodem*` style port:

```bash
arduino-cli board list
./tools/flash-launcher.sh /dev/cu.usbmodemXXXX
```

If no port appears:

- Use a data-capable USB-C cable.
- Reconnect the Cardputer.
- Let the helper perform the 1200-baud touch when a current port exists.
- Check `arduino-cli board list` again after the board re-enumerates.

Do not claim a launcher flash succeeded unless upload output actually completed.

## App Did Not Return To Launcher

Return behavior is implemented inside each app. If an app does not return:

- Use the documented return shortcut for that app in [App Catalog](APP_CATALOG.md).
- Power-cycle the Cardputer if the app is stuck.
- If boot behavior auto-launches an installed app repeatedly, use the launcher
  after a return or erase the installed app slot from the launcher.

`erase` only invalidates the installed app partition. The launcher remains
installed.

## ESP32 Pokedex Data Missing

Cypher OS packages the Pokedex app binary, but the larger local data set is
expected on SD:

```text
/pokemon/
/audio/
/config/
```

If the app opens but data or sprites are missing, copy those folders from the
Pokedex data source to the SD root.

## Cardputer MPC Assets Missing

Cardputer MPC can run with fallback material, but the full package expects:

```text
/cardputer-mpc/
/cardputer-mpc/samples/
/cardputer-mpc/kits/
/cardputer-mpc/projects/
```

If packaging locally, make sure the sibling `cardputer-mpc` repo exists or set:

```bash
CYPHER_OS_CARDPUTER_MPC_DIR=/path/to/cardputer-mpc ./tools/package-sd.sh
```

## Cypher Drive / ESP32 BT HID Payloads Missing

Both apps share:

```text
/cypher-drive/payloads/
/cypher-drive/payloads.json
```

If the payload list is empty, package again with the sibling `ESP32_BT_HID` repo
available or set:

```bash
CYPHER_OS_ESP32_BT_HID_DIR=/path/to/ESP32_BT_HID ./tools/package-sd.sh
```

Use HID payloads only on devices and accounts you own or have explicit
permission to test.
