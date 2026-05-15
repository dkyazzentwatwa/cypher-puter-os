# Repository Guidelines

This repo is Arduino CLI only. Do not add PlatformIO, ESP-IDF project files, or
multi-board support unless the user explicitly changes scope.

## Commands

Use the Cardputer ADV profile:

```bash
arduino-cli compile --profile adv /Users/cypher/Documents/GitHub/cypher-puter-os
```

Flash with the local helper:

```bash
/Users/cypher/Documents/GitHub/cypher-puter-os/tools/flash-launcher.sh /dev/cu.usbmodemXXXX
```

Build and package SD apps:

```bash
/Users/cypher/Documents/GitHub/cypher-puter-os/tools/build-apps.sh
/Users/cypher/Documents/GitHub/cypher-puter-os/tools/package-sd.sh
```

## Scope

- Target hardware: M5Stack Cardputer ADV.
- Supported launch model: SD catalog installs app `.bin` files into the app
  partition, then reboots.
- Keep the launcher small and local. No online OTA catalog, WebUI, USB mass
  storage, multi-board ports, or PlatformIO.

## App Status

`cardputer-games`, `cypher-chat`, and `cypher-drive` are treated as buildable
Cardputer app targets. `flock-you`, `WireTap-32`, and `starbeam_v2` must remain
catalog placeholders until a real Cardputer ADV port exists and compiles.
