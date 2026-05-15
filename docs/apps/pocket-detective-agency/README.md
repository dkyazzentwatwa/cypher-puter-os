# Pocket Detective

## Overview

Pocket Detective is an imported Cypher Game OS title in the Cypher OS SD catalog. Genre: Notebook mystery.

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

- Cypher OS app binary: `/cypher-puter/apps/pocket-detective-agency.bin`.
- Save path: `/cardputer-game-os/saves/pocket-detective-agency/save.sav`.
- Imported from: `/Users/cypher/Documents/GitHub/cardputer-game-os`.

## Return To Cypher OS

From the title screen, press `Backspace` or `Q` to return to the launcher path exposed by the Game OS runtime.

## Player Manual


Genre: notebook mystery game.

## Overview

Pocket Detective Agency is about working cases, visiting locations, interviewing suspects, collecting clues, comparing evidence, and making accusations.

## Goal Of A Run

Solve cases with enough proof to protect your reputation and trust. Fast guesses can close a case, but weak proof can cause wrong arrests, partial truths, or coverups.

## Controls

Use `1` through `5` for visible actions. Move with `W/S`, `K/J`, or `;/.`. Page with `A/D`. Select with `Enter` or BtnA. Back out with `Q` or Backspace.

## Saving, Loading, And Launcher Return

The agency autosaves after case actions. Save path:

```text
/cardputer-game-os/saves/pocket-detective-agency/save.sav
```

Return to launcher from the title screen with `Q` or Backspace.

## Resources

| Resource | Meaning |
|---|---|
| `Cash` | Agency funds. |
| `Time` | Investigation time. |
| `Rep` | Public reputation. |
| `Heat` | Pressure from bad leads and public attention. |
| `Clues` | Evidence gathered. |
| `Trust` | Client and witness confidence. |

## Screen Guide

### AGENCY

AGENCY opens and reviews cases such as Glass Cat, Missing Key, Red Receipt, and Old Names.

### CASE FILE

CASE FILE studies the client, clock, suspects, motives, reward, and risk.

### MAP

MAP visits diners, alleys, offices, piers, libraries, and depots to discover leads.

### INTERVIEW

INTERVIEW asks about alibi, debt, noise, receipt, key, motive, witness, and time. Good interviews reveal contradictions.

### CLUE BOOK

CLUE BOOK reviews receipts, footprints, photos, ledgers, keys, threads, tickets, and notes.

### COMPARE

COMPARE links two clue ideas. Strong pairs create notebook links or contradiction clues.

### ACCUSE

ACCUSE closes a case. Outcomes include full truth, partial truth, wrong lead, and coverup paths.

## Core Loop

1. Open a case at AGENCY.
2. Read CASE FILE.
3. Visit MAP locations.
4. INTERVIEW suspects.
5. Review CLUE BOOK.
6. COMPARE evidence.
7. ACCUSE only when proof is strong.

## Risk, Progress, And Endings

Cash, time, reputation, heat, clues, and trust decide whether your agency becomes respected or compromised. Endings include honest agency, famous sleuth, quiet fixer, cold file, wrong arrest, and true case.

## Tips For First Run

- Do not accuse as soon as you find one clue.
- Compare clues after every new location.
- Trust helps interviews.
- Heat makes poor choices more expensive.
- Time is a resource; use it with purpose.

## Offline Fictional Scope

All cases, interviews, clues, comparisons, accusations, and investigation systems are fictional offline puzzles. Pocket Detective does not perform real surveillance, lookup, credential access, internet research, tracking, or live data gathering.

## Source Docs Used

- `/Users/cypher/Documents/GitHub/cardputer-game-os/manuals/pocket-detective-agency.md`
- `/Users/cypher/Documents/GitHub/cardputer-game-os/manuals/README.md`
