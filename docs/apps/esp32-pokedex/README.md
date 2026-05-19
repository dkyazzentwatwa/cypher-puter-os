# ESP32 Pokedex

## Overview

ESP32 Pokedex is an offline Pokemon GO-style field guide for the Cardputer. It
searches local SD data by name, Pokedex number, form, or tag, then opens compact
battle-guide pages with types, matchups, evolution, GO stats, moves, notes, and
sprites.

## What It Does

- Streams `/pokemon/index.csv` line by line so the catalog stays SD-backed.
- Opens individual JSON records from `/pokemon/data/` only when selected.
- Draws 40x40 BMP sprites from `/pokemon/sprites/` when available.
- Plays optional SD-backed background music plus procedural sound effects.
- Saves audio settings in `/config/settings.json`.

## Controls

- Home: choose Search, Browse Pokedex, Settings, or Return to Cypher OS.
- Search: type a name, number, form, or tag; press `Enter` or `Space` to search.
- Move: `;`, `,`, `W`, or `K` up; `.`, `/`, `S`, or `J` down.
- Detail pages: `A`/`H` previous page; `D`/`L`, `Enter`, or `Space` next page.
- Back: `Backspace`, `Delete`, `Tab`, backtick, or `Q` inside the app.
- Mute: `M` outside the search text screen.

## SD And Runtime Files

- Pokemon index: `/pokemon/index.csv`
- Pokemon records: `/pokemon/data/*.json`
- Pokemon sprites: `/pokemon/sprites/*.bmp`
- Sprite manifest: `/pokemon/sprites/sprite_manifest.csv`
- Optional music: `/audio/bgm/pokedex_loop.wav`
- Audio credits: `/audio/credits.txt`
- Audio settings: `/config/settings.json`
- Cypher OS app binary: `/cypher-puter/apps/esp32-pokedex.bin`

Cypher OS packages only the app `.bin` and catalog entry. The Pokemon data,
sprites, audio, and config folders are expected to already be on the SD card.

## Return To Cypher OS

Choose `Return to Cypher OS` from the home menu. The app stops audio, sets the
shared launcher return flag, switches the boot partition back to the launcher,
and restarts.

## Source Docs Used

- README.md from /Users/cypher/Documents/GitHub/esp32-pokedex
- Cypher OS package notes
