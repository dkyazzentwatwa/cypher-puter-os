# ESP32 BT HID

## Cypher OS Package

| Field | Value |
| --- | --- |
| Catalog slug | `esp32-bt-hid` |
| SD binary | `/cypher-puter/apps/esp32-bt-hid.bin` |
| Source repo | https://github.com/dkyazzentwatwa/ESP32_BT_HID |
| Local source path | `/Users/cypher/Documents/GitHub/ESP32_BT_HID` |
| Build profile | `cardputer` |
| Extra SD paths | `/cypher-drive/payloads/`, `/cypher-drive/payloads.json` |
| Return path | Press backtick, Esc, or Del from the top-level device list. |
| Package note | Cardputer ADV BLE-HID payload deck with SD-backed DuckyScript payloads and Cypher OS return support. |
| Use it when | You want a BLE keyboard payload app with SD-backed DuckyScript files and a Wi-Fi editor. |

## Overview

ESP32 BT HID is the Cardputer ADV build of the ESP32_BT_HID payload deck. In Cypher OS it is a separate BLE keyboard payload app that reads DuckyScript files from SD and exposes a Wi-Fi editor for managing them.

## What It Does

- Presents payload folders for iOS, macOS, and Windows from the SD card.
- Pairs with a target as a BLE keyboard, not USB HID.
- Previews `.duck` payload text before firing it.
- Hosts a local Wi-Fi AP and browser editor for reading, writing, deleting, reloading, and running payload files.
- Shares the `/cypher-drive/payloads/` SD path with Cypher Drive so one payload bundle can serve both apps.

Use HID payloads only on devices and accounts you own or have explicit permission to test.

## Controls

- `,`, `;`, `W`, or `K`: move up.
- `.`, `/`, `S`, or `J`: move down.
- `Enter`: select, preview, or fire.
- Backtick, `Esc`, or `Del`: back.
- From the top-level device list, backtick, `Esc`, or `Del` returns to Cypher OS in the packaged build.

## SD And Runtime Files

- Cypher OS app binary: `/cypher-puter/apps/esp32-bt-hid.bin`.
- Payload catalog: `/cypher-drive/payloads/`.
- Payload manifest: `/cypher-drive/payloads.json`.
- The app can seed a fallback payload if no SD payloads are present, but the Cypher OS package includes the full bundled payload tree.

## Return To Cypher OS

Press backtick, `Esc`, or `Del` from the top-level device list. The packaged build links Cypher OS return support, marks the one-shot launcher return flag, selects the launcher partition, and restarts.

## Source Docs Used

- README.md from /Users/cypher/Documents/GitHub/ESP32_BT_HID
- Cypher OS app manifest notes
