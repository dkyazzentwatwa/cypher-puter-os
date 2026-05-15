# Repository Guidelines

This repo is Arduino CLI only. Do not add PlatformIO, ESP-IDF project files, or
multi-board support unless the user explicitly changes scope.

## Commands

Use the Cardputer ADV profile:

```bash
arduino-cli compile --profile adv .
```

Flash with the local helper:

```bash
./tools/flash-launcher.sh /dev/cu.usbmodemXXXX
```

Build and package SD apps:

```bash
./tools/build-apps.sh
./tools/package-sd.sh
```

## Scope

- Target hardware: M5Stack Cardputer ADV.
- Supported launch model: SD catalog installs app `.bin` files into the app
  partition, then reboots.
- Keep the launcher small and local. No online OTA catalog, WebUI, USB mass
  storage, multi-board ports, or PlatformIO.

## App Status

`cardputer-games`, `cardputer-mpc`, `cardputer-tarot`, `cypher-chat`,
`cypher-drive`, `cypher-desk`, `flock-you`, and `WireTap-32` are treated as
buildable Cardputer app targets. Individual `cardputer-game-os` games are
imported from the sibling repo when that repo is present and builds
successfully. `starbeam_v2` is no longer part of the catalog.

The app build scripts default to sibling repos beside this checkout. Use
`CYPHER_OS_WORKSPACE_ROOT=/path/to/repos` or the per-app `CYPHER_OS_*_DIR`
overrides documented in the README for nonstandard layouts.
