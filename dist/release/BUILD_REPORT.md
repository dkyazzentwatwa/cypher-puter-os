# Cypher OS Build Report

- Generated: `2026-06-05T04:42:00+00:00`
- Release version: `v0.1.3`
- Requested app: `all`
- Ready app entries: `35`
- Failed primary apps: `0`
- Skipped primary apps: `0`
- Missing primary apps: `0`

## Ready Apps

| App | Slug | Binary | Size | Source Commit |
| --- | --- | --- | ---: | --- |
| Cypher Drive | `cypher-drive` | `cypher-drive.bin` | 1689616 | `b8462fe` |
| ESP32 BT HID | `esp32-bt-hid` | `esp32-bt-hid.bin` | 1386800 | `bb11aa9` |
| ESP32 Pokedex | `esp32-pokedex` | `esp32-pokedex.bin` | 614000 | `96d6afa` |
| Cypher Chat | `cypher-chat` | `cypher-chat.bin` | 1409392 | `0c4bc58` |
| Cardputer Games | `cardputer-games` | `cardputer-games.bin` | 647504 | `bc64fd8` |
| Cardputer MPC | `cardputer-mpc` | `cardputer-mpc.bin` | 612736 | `0a428d4` |
| Cardputer Tarot | `cardputer-tarot` | `cardputer-tarot.bin` | 712800 | `7870413` |
| Cypher PN532 | `cypher-pn532` | `cypher-pn532.bin` | 1444960 | `87cf07b` |
| Cypher Desk | `cypher-desk` | `cypher-desk.bin` | 550096 | `041353f` |
| Flock You | `flock-you` | `flock-you.bin` | 1429264 | `f34fac7` |
| WireTap-32 Cardputer | `wiretap-32-cardputer` | `wiretap-32-cardputer.bin` | 624272 | `9c5bac8` |
| Drone Mesh Mapper | `drone-mesh-mapper` | `drone-mesh-mapper.bin` | 1323072 | `efe96b6` |
| Bitcoin Card Wallet | `bitcoin-card-wallet` | `bitcoin-card-wallet.bin` | 1506336 | `4ad82ed` |
| Cardputer Game Station Emulators | `cardputer-game-station-emulators` | `cardputer-game-station-emulators.bin` | 2606832 | `4ad82ed` |
| ESP32 Bit Pirate | `esp32-bit-pirate` | `esp32-bit-pirate.bin` | 3592592 | `4ad82ed` |
| ESP32 USB Stick | `esp32-usb-stick` | `esp32-usb-stick.bin` | 628784 | `4ad82ed` |
| News Reader | `news-reader` | `news-reader.bin` | 1231408 | `4ad82ed` |
| Open WiFi Scanner | `open-wifi-scanner` | `open-wifi-scanner.bin` | 1294624 | `4ad82ed` |
| Password Manager | `password-manager` | `password-manager.bin` | 787360 | `4ad82ed` |
| Ultimate Remote | `ultimate-remote` | `ultimate-remote.bin` | 3467584 | `4ad82ed` |
| Star Trader | `star-trader-pocket-frontier` | `star-trader-pocket-frontier.bin` | 580048 | `5d8bb51` |
| Dungeon Courier | `dungeon-courier` | `dungeon-courier.bin` | 579456 | `5d8bb51` |
| Tiny Wasteland | `tiny-wasteland` | `tiny-wasteland.bin` | 579648 | `5d8bb51` |
| Pocket Kingdom | `pocket-kingdom-manager` | `pocket-kingdom-manager.bin` | 580800 | `5d8bb51` |
| Monster Ranch | `monster-ranch-trail` | `monster-ranch-trail.bin` | 580096 | `5d8bb51` |
| Guildmaster | `guildmaster-pocket` | `guildmaster-pocket.bin` | 579808 | `5d8bb51` |
| Haunted Radio | `haunted-radio-operator` | `haunted-radio-operator.bin` | 580112 | `5d8bb51` |
| Cyberdeck RPG | `cyberdeck-hacker-rpg` | `cyberdeck-hacker-rpg.bin` | 579744 | `5d8bb51` |
| Pocket Detective | `pocket-detective-agency` | `pocket-detective-agency.bin` | 579600 | `5d8bb51` |
| Cryptid Ranger | `cryptid-park-ranger` | `cryptid-park-ranger.bin` | 579568 | `5d8bb51` |
| Cyber Ranger | `cyber-ranger` | `cyber-ranger.bin` | 578912 | `5d8bb51` |
| Star Trail Ranch | `star-trail-rancher` | `star-trail-rancher.bin` | 580288 | `5d8bb51` |
| Waste Guild | `wasteland-guildmaster` | `wasteland-guildmaster.bin` | 580080 | `5d8bb51` |
| Signal Rat | `signal-rat-cyberdeck-rpg` | `signal-rat-cyberdeck-rpg.bin` | 579984 | `5d8bb51` |
| Poke-Trail | `poke-trail` | `poke-trail.bin` | 609008 | `5d8bb51` |

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
- News Reader ships a placeholder `/news-reader/config.example.txt`; copy it to `/news-reader/config.txt` and fill Wi-Fi plus Guardian API values on the SD card.
- ESP32 Pokedex ships as an app binary here; full sprite/audio/data content still belongs at `/pokemon`, `/audio`, and `/config`.
