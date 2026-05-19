# Star Trader

## Cypher OS Package

| Field | Value |
| --- | --- |
| Catalog slug | `star-trader-pocket-frontier` |
| SD binary | `/cypher-puter/apps/star-trader-pocket-frontier.bin` |
| Source repo | https://github.com/dkyazzentwatwa/cardputer-game-os |
| Local source path | `/Users/cypher/Documents/GitHub/cardputer-game-os` |
| Build profile | `cardputer-game-os` import |
| Extra SD paths | `/cardputer-game-os/saves/star-trader-pocket-frontier/save.sav` |
| Return path | Use the imported game's title-screen return control, usually `Backspace` or `Q`. |
| Package note | Imported Cardputer Game OS title: Ship trading sim. Cypher OS packages the individual game binary, not the nested Game OS launcher. |
| Use it when | You want this imported offline Game OS title as an individual Cypher OS app. |

## Overview

Star Trader is an imported Cypher Game OS title in the Cypher OS SD catalog. Genre: Ship trading sim.

## What It Does

The full player manual from Cypher Game OS is included below. This game is an offline, compiled-data Cardputer game; it does not depend on internet access or external services at runtime.

## Controls

- Move up: `W`, `K`, `;`, or `,`.
- Move down: `S`, `J`, `.`, or `/`.
- Change page where available: `A` / `D` or left / right.
- Select: `Enter`, `Space`, or BtnA.
- Pick visible action: `1` through `5`.
- Back: `Backspace`, `Delete`, `Tab`, backtick, or `Q`.
- Return from title screen: `Backspace` or `Q`.

## SD And Runtime Files

- Cypher OS app binary: `/cypher-puter/apps/star-trader-pocket-frontier.bin`.
- Save path: `/cardputer-game-os/saves/star-trader-pocket-frontier/save.sav`.
- Imported from: `/Users/cypher/Documents/GitHub/cardputer-game-os`.

## Return To Cypher OS

From the title screen, press `Backspace` or `Q` to return to the launcher path exposed by the Game OS runtime.

## Player Manual


Genre: ship-console trading sim.

## Overview

Star Trader puts you in charge of a small frontier ship. You buy goods, choose routes, hire crew, upgrade the ship, and manage pressure from debt, heat, hull wear, oxygen, and fuel.

## Goal Of A Run

Reach the campaign progress target before your ship economy collapses. A strong run balances profitable cargo with survival resources. High credits help, but fuel, oxygen, hull, morale, and debt pressure decide whether you arrive as a merchant legend or a lost ship.

## Controls

Use `1` through `5` to choose visible actions. Use `W/S`, `K/J`, or `;/.` to move. Use `A/D` to change pages where a screen has more rows. Press `Enter` or BtnA to select. Press `Q`, `Backspace`, `Delete`, or `Tab` to back out.

## Saving, Loading, And Launcher Return

Star Trader autosaves after deep actions. The save file is:

```text
/cardputer-game-os/saves/star-trader-pocket-frontier/save.sav
```

From the title screen, choose Continue to load or New Run to reset. Press `Q` or Backspace on the title screen to return to the launcher.

## Resources

| Resource | Meaning |
|---|---|
| `Cr` | Credits for trading, crew, repairs, and upgrades. |
| `Fuel` | Spent on routes. Low fuel makes travel dangerous. |
| `O2` | Oxygen reserve for long jumps. |
| `Hull` | Ship condition. Low hull points toward failure. |
| `Heat` | Frontier attention from patrols, risky cargo, and bad choices. |
| `Cargo` | Cargo pressure and capacity use. |
| `Mor` | Crew morale during long and dangerous routes. |
| `Debt` | Long-term financial pressure. |

## Screen Guide

### BRIDGE

Use BRIDGE to review the ship situation and choose strategic leads. Bridge actions include rumors, debt review, crew notes, artifact leads, patrol pressure, fuel checks, dock planning, and distress calls.

### MARKET

MARKET handles trading. Goods include spice, water, medgel, relics, scrap, kelp, cores, and textiles. Market actions change credits, cargo pressure, and sometimes heat.

### ROUTES

ROUTES is the main travel screen. Routes spend fuel and oxygen, apply hull risk, and trigger route events. Short routes are safer; longer or stranger routes push progress faster.

### CARGO

CARGO lets you manage goods and avoid overloading. Use it when heat or cargo pressure is rising.

### CREW

CREW adds specialists such as pilots, brokers, medics, mechanics, scouts, cooks, shield techs, and archivists. Crew actions improve long-run survival but cost credits.

### SHIP

SHIP installs upgrades such as cargo bay, fuel tank, oxygen recycler, shield, scanner, hold, engine, and med bay. Upgrades help offset route pressure.

### LOG

LOG tracks artifact, courier, faction, debt, crew, relic, patrol, salvage, gate, and rumor threads. Use it to push ending paths and understand story pressure.

## Core Loop

1. Check BRIDGE for ship pressure.
2. Trade or manage cargo if credits are low.
3. Pick a route that your fuel, oxygen, and hull can survive.
4. Use crew and ship upgrades to reduce future losses.
5. Read LOG when story flags or ending pressure matter.

## Risk, Progress, And Endings

Progress comes fastest from routes and major story actions. Heat, debt, low hull, low oxygen, and poor morale create bad endings. Strong credits and managed resources point toward Merchant Star, Frontier Hero, Relic Wake, Smuggler Lord, Corporate Pawn, or Lost Ship outcomes.

## Tips For First Run

- Do not spend all credits on cargo before checking fuel and oxygen.
- Keep hull above the danger zone.
- Use crew early if you keep losing the same resource.
- High heat is not instant failure, but it makes route events harsher.
- Debt can be managed over time; a dead ship cannot.

## Offline Fictional Scope

Scanner, customs, pirate, salvage, faction, and route systems are fictional offline table events. Star Trader does not perform real networking, radio use, scanning, internet access, tracking, or trading.

## Source Docs Used

- `/Users/cypher/Documents/GitHub/cardputer-game-os/manuals/star-trader-pocket-frontier.md`
- `/Users/cypher/Documents/GitHub/cardputer-game-os/manuals/README.md`
