# Cypher PN532

## Cypher OS Package

| Field | Value |
| --- | --- |
| Catalog slug | `cypher-pn532` |
| SD binary | `/cypher-puter/apps/cypher-pn532.bin` |
| Source repo | https://github.com/dkyazzentwatwa/cypher-pn532 |
| Local source path | `/Users/cypher/Documents/GitHub/cypher-pn532` |
| Build profile | `cardputer-adv-pn532` |
| Extra SD paths | `/cypher-pn532/` |
| Return path | Use Return to Cypher OS, or press Del, Tab, backtick, or Q from the main menu. |
| Package note | Cardputer ADV PN532 NFC app using EXT I2C on G8/G9 with SD-backed dumps, read-only SD web browser, and return-to-launcher support. |
| Use it when | You have a PN532 module on the Cardputer ADV EXT I2C header and want NFC tools. |

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
- Launch a read-only SD web server for browsing and downloading PN532 files.

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

## Read-Only SD Web Server

Choose `SD Web Server` from the main menu to start a local access point:

- SSID: `CYPHER-PN532`
- Password: `cypher532`
- URL: `http://192.168.4.1`

The web dashboard lists files under `/cypher-pn532/`, shows PN532/SD status,
previews text and binary dump files, and downloads saved dumps. It is read-only:
there are no upload, edit, delete, clone, or NDEF-write actions in the browser.
Press `Del`, `Tab`, backtick, `Q`, `Enter`, `Space`, or BtnA on the Cardputer
server screen to stop Wi-Fi and return to the app menu.

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
