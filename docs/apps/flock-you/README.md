# Flock You

## Cypher OS Package

| Field | Value |
| --- | --- |
| Catalog slug | `flock-you` |
| SD binary | `/cypher-puter/apps/flock-you.bin` |
| Source repo | https://github.com/dkyazzentwatwa/cypher-flock |
| Local source path | `/Users/cypher/Documents/GitHub/flock-you` |
| Build profile | `cardputer-adv-detector` |
| Extra SD paths | None required beyond `/cypher-puter/apps/`. |
| Return path | Open the mini menu, cycle to HOME, then press up/down to return. |
| Package note | Cardputer ADV WiFi/BLE detector build with return-to-launcher support. |
| Use it when | You want the compact WiFi/BLE detector build adapted for the Cardputer ADV. |

## Overview

Flock You is the Cypher Flock detector app in the Cypher OS catalog: a compact WiFi/BLE detector build adapted for Cardputer ADV controls and display.

## What It Does

- Passively listens on 2.4 GHz WiFi.
- Checks frames for known target OUIs and related signatures.
- Scans BLE advertisements for Flock/Raven signatures with confidence scoring.
- Shows live status and activity pages on-device.
- Can save detections locally and emit JSON lines over USB serial in upstream profiles.

Use wireless detection only where passive monitoring is legal and authorized.

## Controls

- Cardputer ADV profile uses built-in screen, keyboard, and BtnA.
- Up/down change pages or values; select opens and steps through the menu in the upstream button model.
- For Cypher OS return: open the mini menu, cycle to `HOME`, then press up/down to return.

## SD And Runtime Files

- Upstream firmware can save detections/logs locally depending on profile.
- Cypher OS app binary: `/cypher-puter/apps/flock-you.bin`.

## Return To Cypher OS

Open the mini menu, cycle to `HOME`, then press up/down. The Cardputer package includes return-to-launcher support.

## Source Docs Used

- README.md from /Users/cypher/Documents/GitHub/flock-you
- Cypher OS README controls
