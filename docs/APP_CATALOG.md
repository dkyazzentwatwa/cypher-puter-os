# App Catalog

This page is the quick reference for Cypher OS app metadata. The source of truth
for primary app packaging is `config/apps.json`; this page mirrors that catalog
in user-readable form.

App binaries live on SD under:

```text
/cypher-puter/apps/
```

The launcher catalog lives at:

```text
/cypher-puter/apps/apps.json
```

## Primary Apps

| App | Slug | Binary | Build Profile | SD Paths | Return To Launcher |
| --- | --- | --- | --- | --- | --- |
| [Cypher Drive](apps/cypher-drive/README.md) | `cypher-drive` | `cypher-drive.bin` | `cardputer-adv-hid` | `/cypher-drive/payloads/`, `/cypher-drive/payloads.json` | Use the app's Return to Launcher item where shown. |
| [ESP32 BT HID](apps/esp32-bt-hid/README.md) | `esp32-bt-hid` | `esp32-bt-hid.bin` | `cardputer` | `/cypher-drive/payloads/`, `/cypher-drive/payloads.json` | Press backtick, `Esc`, or `Del` from the top-level device list. |
| [ESP32 Pokedex](apps/esp32-pokedex/README.md) | `esp32-pokedex` | `esp32-pokedex.bin` | `cardputer-adv` | `/pokemon/`, `/audio/`, `/config/` | Choose Return to Cypher OS from the home menu. |
| [Cypher Chat](apps/cypher-chat/README.md) | `cypher-chat` | `cypher-chat.bin` | `cardputer-adv-secure-mesh` | None required | Use the app's Return to Launcher item where shown. |
| [Cardputer Games](apps/cardputer-games/README.md) | `cardputer-games` | `cardputer-games.bin` | `cardputer-adv` | None required | Use the app's Return to Launcher item where shown. |
| [Cardputer MPC](apps/cardputer-mpc/README.md) | `cardputer-mpc` | `cardputer-mpc.bin` | `cardputer` | `/cardputer-mpc/` | Press `Shift+Q`; lowercase `q` remains an MPC pad trigger. |
| [Cardputer Tarot](apps/cardputer-tarot/README.md) | `cardputer-tarot` | `cardputer-tarot.bin` | `cardputer-adv` | `/cardputer-tarot/` | Back/backtick from the main menu returns to Cypher OS. |
| [Cypher PN532](apps/cypher-pn532/README.md) | `cypher-pn532` | `cypher-pn532.bin` | `cardputer-adv-pn532` | `/cypher-pn532/` | Use Return to Cypher OS, or press `Del`, `Tab`, backtick, or `Q` from the main menu. |
| [Cypher Desk](apps/cypher-desk/README.md) | `cypher-desk` | `cypher-desk.bin` | `cardputer-adv` | `/cypher-puter/desk/` | Use Return to Launcher from the app menu. |
| [Flock You](apps/flock-you/README.md) | `flock-you` | `flock-you.bin` | `cardputer-adv-detector` | None required | Open the mini menu, cycle to `HOME`, then press up/down to return. |
| [WireTap-32 Cardputer](apps/wiretap-32-cardputer/README.md) | `wiretap-32-cardputer` | `wiretap-32-cardputer.bin` | `cardputer-adv-ext-bench` | None required | Choose Launcher from the main menu, or type `launcher` / `return` over serial. |

## Imported Cardputer Game OS Titles

These titles are imported from the sibling `cardputer-game-os` repo when that
repo is present and its games build successfully. Cypher OS packages individual
game `.bin` files; it does not package the nested Game OS launcher because
Cypher OS already owns the launcher partition.

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

## Source Repositories

| Source | Default Local Path |
| --- | --- |
| Cypher OS launcher | `/Users/cypher/Documents/GitHub/cypher-puter-os` |
| Cardputer Games | `/Users/cypher/Documents/GitHub/cardputer-games` |
| Cardputer MPC | `/Users/cypher/Documents/GitHub/cardputer-mpc` |
| Cardputer Tarot | `/Users/cypher/Documents/GitHub/cardputer-tarot` |
| Cypher PN532 | `/Users/cypher/Documents/GitHub/cypher-pn532` |
| Cypher Chat firmware | `/Users/cypher/Documents/GitHub/cypher-chat/cypher-chat-firmware` |
| Cypher Drive | `/Users/cypher/Documents/GitHub/cypher-drive` |
| ESP32 BT HID | `/Users/cypher/Documents/GitHub/ESP32_BT_HID` |
| ESP32 Pokedex | `/Users/cypher/Documents/GitHub/esp32-pokedex` |
| Cypher Desk | `/Users/cypher/Documents/GitHub/cypher-desk` |
| Flock You / Cypher Flock | `/Users/cypher/Documents/GitHub/flock-you` |
| WireTap-32 | `/Users/cypher/Documents/GitHub/WireTap-32` |
| Cardputer Game OS | `/Users/cypher/Documents/GitHub/cardputer-game-os` |
| Poke-Trail | `/Users/cypher/Documents/GitHub/poke-trail` |

`starbeam_v2` is intentionally excluded from the current Cypher OS catalog.
