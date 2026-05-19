# Cypher OS Docs

Cypher OS is a local-first app launcher for the M5Stack Cardputer ADV. Flash the
launcher once, copy the SD bundle, then install apps from the on-device catalog
without reflashing over USB every time.

This folder is the deeper manual for people who want to understand the whole
system: first install, SD layout, launcher behavior, app docs, local builds, and
recovery notes.

## Start Here

| Path | Use This When |
| --- | --- |
| [Getting Started](GETTING_STARTED.md) | You are new to Cypher OS and want the shortest release-install path. |
| [Launcher Model](LAUNCHER_MODEL.md) | You want to understand why apps install from SD into the app partition before rebooting. |
| [App Catalog](APP_CATALOG.md) | You want every app slug, binary name, SD path, build profile, and return behavior. |
| [Building And Packaging](BUILDING_AND_PACKAGING.md) | You want to build the launcher or SD bundle locally with Arduino CLI. |
| [Troubleshooting](TROUBLESHOOTING.md) | The SD card, catalog, install, USB port, or return-to-launcher flow is not behaving. |

If you only want to use a public release, start with
[Getting Started](GETTING_STARTED.md). If you are modifying this repo or sibling
apps, read [Building And Packaging](BUILDING_AND_PACKAGING.md) next.

## Mental Model

Cypher OS is not a generic desktop-style operating system and ESP32 apps do not
run directly from SD. The launcher lives in `ota_0`. App `.bin` files live on the
SD card under `/cypher-puter/apps`. When you choose an app, the launcher copies
that app into `ota_1`, marks it as the next boot target, and restarts.

Supported apps can return to Cypher OS by setting the shared launcher return
flag, switching the boot target back to the launcher partition, and rebooting.
That is what makes the device feel like a small app deck instead of a one-app
firmware flash.

## App Docs

Primary app docs:

- [Cypher Drive](apps/cypher-drive/README.md)
- [ESP32 BT HID](apps/esp32-bt-hid/README.md)
- [ESP32 Pokedex](apps/esp32-pokedex/README.md)
- [Cypher Chat](apps/cypher-chat/README.md)
- [Cardputer Games](apps/cardputer-games/README.md)
- [Cardputer MPC](apps/cardputer-mpc/README.md)
- [Cardputer Tarot](apps/cardputer-tarot/README.md)
- [Cypher PN532](apps/cypher-pn532/README.md)
- [Cypher Desk](apps/cypher-desk/README.md)
- [Flock You](apps/flock-you/README.md)
- [WireTap-32 Cardputer](apps/wiretap-32-cardputer/README.md)

Imported Game OS title docs:

- [Star Trader](apps/star-trader-pocket-frontier/README.md)
- [Dungeon Courier](apps/dungeon-courier/README.md)
- [Tiny Wasteland](apps/tiny-wasteland/README.md)
- [Pocket Kingdom](apps/pocket-kingdom-manager/README.md)
- [Monster Ranch](apps/monster-ranch-trail/README.md)
- [Guildmaster](apps/guildmaster-pocket/README.md)
- [Haunted Radio](apps/haunted-radio-operator/README.md)
- [Cyberdeck RPG](apps/cyberdeck-hacker-rpg/README.md)
- [Pocket Detective](apps/pocket-detective-agency/README.md)
- [Cryptid Ranger](apps/cryptid-park-ranger/README.md)
- [Cyber Ranger](apps/cyber-ranger/README.md)
- [Star Trail Ranch](apps/star-trail-rancher/README.md)
- [Waste Guild](apps/wasteland-guildmaster/README.md)
- [Signal Rat](apps/signal-rat-cyberdeck-rpg/README.md)
- [Poke-Trail](apps/poke-trail/README.md)

## Canonical Commands

```bash
arduino-cli compile --profile adv .
./tools/flash-launcher.sh /dev/cu.usbmodemXXXX
./tools/build-apps.sh
./tools/package-sd.sh
```

This repo is Arduino CLI only. Do not add PlatformIO, ESP-IDF project files,
online OTA catalogs, WebUI, USB mass storage mode, or multi-board launcher scope
unless the project direction explicitly changes.

## What Is Not In The Catalog

`starbeam_v2` is intentionally not part of the Cypher OS app catalog and is not
documented as an installable app here.

Generated files and release package output stay under `dist/`; `/docs` is for
user-facing explanations and app manuals.
