# Waste Guild

## Cypher OS Package

| Field | Value |
| --- | --- |
| Catalog slug | `wasteland-guildmaster` |
| SD binary | `/cypher-puter/apps/wasteland-guildmaster.bin` |
| Source repo | https://github.com/dkyazzentwatwa/cardputer-game-os |
| Local source path | `/Users/cypher/Documents/GitHub/cardputer-game-os` |
| Build profile | `cardputer-game-os` import |
| Extra SD paths | `/cardputer-game-os/saves/wasteland-guildmaster/save.sav` |
| Return path | Use the imported game's title-screen return control, usually `Backspace` or `Q`. |
| Package note | Imported Cardputer Game OS title: Settlement command sim. Cypher OS packages the individual game binary, not the nested Game OS launcher. |
| Use it when | You want this imported offline Game OS title as an individual Cypher OS app. |

## Overview

Waste Guild is an imported Cypher Game OS title in the Cypher OS SD catalog. Genre: Settlement command sim.

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

- Cypher OS app binary: `/cypher-puter/apps/wasteland-guildmaster.bin`.
- Save path: `/cardputer-game-os/saves/wasteland-guildmaster/save.sav`.
- Imported from: `/Users/cypher/Documents/GitHub/cardputer-game-os`.

## Return To Cypher OS

From the title screen, press `Backspace` or `Q` to return to the launcher path exposed by the Game OS runtime.

## Player Manual


Genre: settlement command sim.

## Overview

Wasteland Guildmaster puts you in charge of a fragile settlement. You launch expeditions, assign survivor roles, build facilities, answer threats, and keep the base alive.

## Goal Of A Settlement

Build enough survival progress to reach a stable ending before food, water, morale, defense, radiation pressure, or threat clocks break the camp.

## Controls

Use `1` through `5` for visible actions. Move with `W/S`, `K/J`, or `;/.`. Page with `A/D`. Select with `Enter` or BtnA. Back out with `Q` or Backspace.

## Saving, Loading, And Launcher Return

Waste Guild saves after settlement actions. Save path:

```text
/cardputer-game-os/saves/wasteland-guildmaster/save.sav
```

Return to launcher from the title screen with `Q` or Backspace.

## Settlement Resources

| Resource | Meaning |
|---|---|
| `Food` | Settlement food. |
| `Water` | Water supply. |
| `Meds` | Medicine supply. |
| `Ammo` | Expedition and defense supply. |
| `Scrap` | Building and repair material. |
| `Power` | Facility and base power. |
| `Mor` | Morale. |
| `Def` | Defense. |

## Screen Guide

### BASE

BASE checks the settlement week and pressure around food, water, clinic, tower, farm, and depot needs.

### MISSIONS

MISSIONS launches clinic, tower, depot, tunnel, farm, storm, river, and authority expeditions.

### TEAM

TEAM assigns scout, medic, guard, tech, cook, baron, cultist, and radio roles. Role coverage changes expedition results.

### RESULT

RESULT resolves ruin, clinic, depot, tower, farm, tunnel, camp, and signal stages.

### BUILD

BUILD creates garden, purifier, clinic, workshop, barracks, watchtower, radio, school, walls, and storage facilities.

### THREATS

THREATS answers raiders, sickness, storm, hunger, and faction demand clocks.

## Core Loop

1. Check BASE.
2. Launch a mission.
3. Assign a team.
4. Resolve expedition stages.
5. Build facilities.
6. Answer threats before they overwhelm the base.

## Risk, Progress, And Endings

Food and water are survival basics. Meds and defense prevent sudden collapses. Scrap and power enable facilities. Endings include fortress town, mobile convoy, river alliance, signal beacon, bunker rule, and camp collapse.

## Tips For First Run

- Build purifier or garden early.
- Send medics to clinic-style missions.
- Defense matters before raider threat peaks.
- Do not spend all scrap before checking facility needs.
- Threat clocks are warnings; answer them early.

## Offline Fictional Scope

Survival, medicine, ammo, settlement defense, radio, faction, authority, raider, sickness, and disaster content is fictional offline game content. It is not emergency, medical, tactical, radio, network, or survival guidance.

## Source Docs Used

- `/Users/cypher/Documents/GitHub/cardputer-game-os/manuals/wasteland-guildmaster.md`
- `/Users/cypher/Documents/GitHub/cardputer-game-os/manuals/README.md`
