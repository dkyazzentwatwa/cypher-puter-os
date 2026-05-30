# Cypher OS Build Report

- Generated: `2026-05-30T19:28:38+00:00`
- Release version: `v0.1.2`
- Requested app: `all`
- Ready app entries: `27`
- Failed primary apps: `0`
- Skipped primary apps: `0`
- Missing primary apps: `0`

## Ready Apps

| App | Slug | Binary | Size | Source Commit |
| --- | --- | --- | ---: | --- |
| Cypher Drive | `cypher-drive` | `cypher-drive.bin` | 1689616 | `b8462fe` |
| ESP32 BT HID | `esp32-bt-hid` | `esp32-bt-hid.bin` | 1371280 | `bb11aa9` |
| ESP32 Pokedex | `esp32-pokedex` | `esp32-pokedex.bin` | 614000 | `96d6afa` |
| Cypher Chat | `cypher-chat` | `cypher-chat.bin` | 1409392 | `0c4bc58` |
| Cardputer Games | `cardputer-games` | `cardputer-games.bin` | 557424 | `ffeb78a` |
| Cardputer MPC | `cardputer-mpc` | `cardputer-mpc.bin` | 612736 | `0a428d4` |
| Cardputer Tarot | `cardputer-tarot` | `cardputer-tarot.bin` | 712800 | `7870413` |
| Cypher PN532 | `cypher-pn532` | `cypher-pn532.bin` | 1444960 | `87cf07b` |
| Cypher Desk | `cypher-desk` | `cypher-desk.bin` | 550096 | `041353f` |
| Flock You | `flock-you` | `flock-you.bin` | 1429264 | `f1ea971` |
| WireTap-32 Cardputer | `wiretap-32-cardputer` | `wiretap-32-cardputer.bin` | 624272 | `bf5ea1f` |
| Drone Mesh Mapper | `drone-mesh-mapper` | `drone-mesh-mapper.bin` | 1323072 | `efe96b6` |
| Star Trader | `star-trader-pocket-frontier` | `star-trader-pocket-frontier.bin` | 578640 | `aeb476a` |
| Dungeon Courier | `dungeon-courier` | `dungeon-courier.bin` | 583120 | `aeb476a` |
| Tiny Wasteland | `tiny-wasteland` | `tiny-wasteland.bin` | 579392 | `aeb476a` |
| Pocket Kingdom | `pocket-kingdom-manager` | `pocket-kingdom-manager.bin` | 582144 | `aeb476a` |
| Monster Ranch | `monster-ranch-trail` | `monster-ranch-trail.bin` | 580192 | `aeb476a` |
| Guildmaster | `guildmaster-pocket` | `guildmaster-pocket.bin` | 581344 | `aeb476a` |
| Haunted Radio | `haunted-radio-operator` | `haunted-radio-operator.bin` | 580560 | `aeb476a` |
| Cyberdeck RPG | `cyberdeck-hacker-rpg` | `cyberdeck-hacker-rpg.bin` | 581504 | `aeb476a` |
| Pocket Detective | `pocket-detective-agency` | `pocket-detective-agency.bin` | 583360 | `aeb476a` |
| Cryptid Ranger | `cryptid-park-ranger` | `cryptid-park-ranger.bin` | 581648 | `aeb476a` |
| Cyber Ranger | `cyber-ranger` | `cyber-ranger.bin` | 580208 | `aeb476a` |
| Star Trail Ranch | `star-trail-rancher` | `star-trail-rancher.bin` | 578704 | `aeb476a` |
| Waste Guild | `wasteland-guildmaster` | `wasteland-guildmaster.bin` | 582224 | `aeb476a` |
| Signal Rat | `signal-rat-cyberdeck-rpg` | `signal-rat-cyberdeck-rpg.bin` | 576784 | `aeb476a` |
| Poke-Trail | `poke-trail` | `poke-trail.bin` | 609008 | `aeb476a` |

## Not Ready

| App | Slug | Status | Source |
| --- | --- | --- | --- |
| None | `-` | `-` | `-` |

## Imports

| Import | Status | Source |
| --- | --- | --- |
| Cardputer Game OS Games | `ready` | `/Users/cypher/Documents/GitHub/cardputer-game-os` |

## Commands

- Launcher: `./tools/build-launcher.sh` or `arduino-cli compile --profile adv .`
- Apps: `./tools/build-apps.sh` or `./tools/build-apps.sh --app <slug>`
- SD package: `./tools/package-sd.sh`

## SD Notes

- The release SD zip contains the app manifest and built app binaries under `/cypher-puter/apps/`.
- Cardputer MPC runtime assets are packaged under `/cardputer-mpc/` when present.
- Cypher Drive / ESP32 BT HID payload assets are packaged under `/cypher-drive/` when present.
- Drone Mesh Mapper SD seed assets are packaged under `/drone/` when present.
- ESP32 Pokedex ships as an app binary here; full sprite/audio/data content still belongs at `/pokemon`, `/audio`, and `/config`.
