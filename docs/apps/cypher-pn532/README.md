# Cypher PN532

## Overview

Cypher PN532 is the Cardputer ADV port of the Cypher NFC toolkit. It uses a PN532 module on the Cardputer EXT I2C header and saves NFC dump output to the SD card.

## What It Does

- Scan ISO14443A cards and show UID, card type, and size.
- Read UID, NDEF pages, MIFARE Classic blocks, and NTAG pages.
- Run the built-in MIFARE Classic dictionary attack and save key maps.
- Dump MIFARE and NTAG cards to SD as binary plus text files.
- Write simple NDEF URL/text records to NTAG cards.
- Load saved MIFARE dumps and write them to compatible magic cards.
- Browse, hex-view, and delete app files from SD.

Use these features only with tags, cards, and systems you own or have explicit
permission to test.

## Wiring

Use a PN532 module set to I2C mode:

- `VCC` to EXT pin 6 `5VOUT`
- `GND` to EXT pin 4 `GND`
- `SDA` to EXT pin 8 `G8 / I2C_SDA`
- `SCL` to EXT pin 10 `G9 / I2C_SCL`
- Leave `RESET`, `INT`, and `BUSY` unconnected.
- Do not use EXT pin 2 `5VIN`.

## Controls

- Move: `W/S`, `K/J`, or `,/.`.
- Select: `Enter`, `Space`, or BtnA.
- Back/cancel: `Del`, `Tab`, backtick, or `Q`.
- From the main menu, choose `Return to Cypher OS` or press a back key to return to the launcher.

## SD And Runtime Files

- App working folder: `/cypher-pn532/`
- Counter file: `/cypher-pn532/COUNTER.TXT`
- Optional URL preset: `/cypher-pn532/NDEF_URL.TXT` or root `/NDEF_URL.TXT`
- Optional text preset: `/cypher-pn532/NDEF_TXT.TXT` or root `/NDEF_TXT.TXT`
- Cypher OS app binary: `/cypher-puter/apps/cypher-pn532.bin`

## Source Docs Used

- README.md from `/Users/cypher/Documents/GitHub/cypher-pn532`
- CLAUDE.md from `/Users/cypher/Documents/GitHub/cypher-pn532`
- Cypher OS package notes
