# Cypher OS App Docs

This folder is the browseable documentation hub for the full Cypher OS app catalog. It covers the primary Cardputer apps plus imported Cypher Game OS titles that can appear in the SD app catalog.

Cypher OS is still a local SD launcher: app `.bin` files live under `/cypher-puter/apps`, the launcher installs the selected app into the app partition, and supported apps can return to the launcher.

## Primary Apps

| App | Slug | Binary | Summary |
| --- | --- | --- | --- |
| [Cypher Drive](apps/cypher-drive/README.md) | `cypher-drive` | `cypher-drive.bin` | Cypher Drive is the Cardputer ADV build of the portable ESP32-S3 wireless and HID utility firmware. |
| [Cypher Chat](apps/cypher-chat/README.md) | `cypher-chat` | `cypher-chat.bin` | Cypher Chat is the secure-only mesh communication app in the Cypher OS catalog. |
| [Cardputer Games](apps/cardputer-games/README.md) | `cardputer-games` | `cardputer-games.bin` | Cardputer Games is the standalone arcade catalog app. |
| [Cardputer MPC](apps/cardputer-mpc/README.md) | `cardputer-mpc` | `cardputer-mpc.bin` | Cardputer MPC turns the Cardputer into a tiny groovebox: pads, samples, 16-step sequencing, live triggering, project save/load, and a small performance UI. |
| [Cardputer Tarot](apps/cardputer-tarot/README.md) | `cardputer-tarot` | `cardputer-tarot.bin` | Cardputer Tarot is an offline tarot app with a full 78-card symbolic deck, spreads, history, journaling, study mode, favorites, clarifiers, and SD-backed pull records. |
| [Cypher Desk](apps/cypher-desk/README.md) | `cypher-desk` | `cypher-desk.bin` | Cypher Desk is the calm offline writing and utility workspace in the Cypher OS deck. |
| [Flock You](apps/flock-you/README.md) | `flock-you` | `flock-you.bin` | Flock You is the Cypher Flock detector app in the Cypher OS catalog: a compact WiFi/BLE detector build adapted for Cardputer ADV controls and display. |
| [WireTap-32 Cardputer](apps/wiretap-32-cardputer/README.md) | `wiretap-32-cardputer` | `wiretap-32-cardputer.bin` | WireTap-32 Cardputer is the electronics bench companion app in the Cypher OS deck. |

## Imported Game OS Titles

| Game | Slug | Binary | Genre | Save Path |
| --- | --- | --- | --- | --- |
| [Star Trader](apps/star-trader-pocket-frontier/README.md) | `star-trader-pocket-frontier` | `star-trader-pocket-frontier.bin` | Ship trading sim | `/cardputer-game-os/saves/star-trader-pocket-frontier/save.sav` |
| [Dungeon Courier](apps/dungeon-courier/README.md) | `dungeon-courier` | `dungeon-courier.bin` | Delivery RPG | `/cardputer-game-os/saves/dungeon-courier/save.sav` |
| [Tiny Wasteland](apps/tiny-wasteland/README.md) | `tiny-wasteland` | `tiny-wasteland.bin` | Survival road drama | `/cardputer-game-os/saves/tiny-wasteland/save.sav` |
| [Pocket Kingdom](apps/pocket-kingdom-manager/README.md) | `pocket-kingdom-manager` | `pocket-kingdom-manager.bin` | Kingdom ledger sim | `/cardputer-game-os/saves/pocket-kingdom-manager/save.sav` |
| [Monster Ranch](apps/monster-ranch-trail/README.md) | `monster-ranch-trail` | `monster-ranch-trail.bin` | Creature ranch sim | `/cardputer-game-os/saves/monster-ranch-trail/save.sav` |
| [Guildmaster](apps/guildmaster-pocket/README.md) | `guildmaster-pocket` | `guildmaster-pocket.bin` | Quest desk sim | `/cardputer-game-os/saves/guildmaster-pocket/save.sav` |
| [Haunted Radio](apps/haunted-radio-operator/README.md) | `haunted-radio-operator` | `haunted-radio-operator.bin` | Station mystery | `/cardputer-game-os/saves/haunted-radio-operator/save.sav` |
| [Cyberdeck RPG](apps/cyberdeck-hacker-rpg/README.md) | `cyberdeck-hacker-rpg` | `cyberdeck-hacker-rpg.bin` | Fictional node-crawl | `/cardputer-game-os/saves/cyberdeck-hacker-rpg/save.sav` |
| [Pocket Detective](apps/pocket-detective-agency/README.md) | `pocket-detective-agency` | `pocket-detective-agency.bin` | Notebook mystery | `/cardputer-game-os/saves/pocket-detective-agency/save.sav` |
| [Cryptid Ranger](apps/cryptid-park-ranger/README.md) | `cryptid-park-ranger` | `cryptid-park-ranger.bin` | Field research sim | `/cardputer-game-os/saves/cryptid-park-ranger/save.sav` |
| [Cyber Ranger](apps/cyber-ranger/README.md) | `cyber-ranger` | `cyber-ranger.bin` | Cyber-wilderness mystery | `/cardputer-game-os/saves/cyber-ranger/save.sav` |
| [Star Trail Ranch](apps/star-trail-rancher/README.md) | `star-trail-rancher` | `star-trail-rancher.bin` | Space creature transport | `/cardputer-game-os/saves/star-trail-rancher/save.sav` |
| [Waste Guild](apps/wasteland-guildmaster/README.md) | `wasteland-guildmaster` | `wasteland-guildmaster.bin` | Settlement command sim | `/cardputer-game-os/saves/wasteland-guildmaster/save.sav` |
| [Signal Rat](apps/signal-rat-cyberdeck-rpg/README.md) | `signal-rat-cyberdeck-rpg` | `signal-rat-cyberdeck-rpg.bin` | Flagship cyberdeck RPG | `/cardputer-game-os/saves/signal-rat-cyberdeck-rpg/save.sav` |
| [Poke-Trail](apps/poke-trail/README.md) | `poke-trail` | `poke-trail.bin` | Creature trail RPG | `/poke-trail/save.sav` |

## Source Repos

| Source | Path |
| --- | --- |
| Cypher OS launcher | `/Users/cypher/Documents/GitHub/cypher-puter-os` |
| Cardputer Games | `/Users/cypher/Documents/GitHub/cardputer-games` |
| Cardputer MPC | `/Users/cypher/Documents/GitHub/cardputer-mpc` |
| Cardputer Tarot | `/Users/cypher/Documents/GitHub/cardputer-tarot` |
| Cypher Chat firmware | `/Users/cypher/Documents/GitHub/cypher-chat/cypher-chat-firmware` |
| Cypher Drive | `/Users/cypher/Documents/GitHub/cypher-drive` |
| Cypher Desk | `/Users/cypher/Documents/GitHub/cypher-desk` |
| Flock You / Cypher Flock | `/Users/cypher/Documents/GitHub/flock-you` |
| WireTap-32 | `/Users/cypher/Documents/GitHub/WireTap-32` |
| Cypher Game OS manuals | `/Users/cypher/Documents/GitHub/cardputer-game-os/manuals` |
| Poke-Trail | `/Users/cypher/Documents/GitHub/poke-trail` |

## Notes

- `starbeam_v2` is intentionally not documented here because it is no longer part of the Cypher OS catalog.
- These docs are user-facing app notes, not build artifacts. Binaries and generated package output stay out of `docs/`.
- Build and flash instructions remain in the root README; app pages focus on what each app does, controls, storage, and return behavior.
