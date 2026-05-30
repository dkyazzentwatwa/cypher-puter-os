# Drone Mesh Mapper

## Cypher OS Package

| Field | Value |
| --- | --- |
| Catalog slug | `drone-mesh-mapper` |
| SD binary | `/cypher-puter/apps/drone-mesh-mapper.bin` |
| Source repo | https://github.com/dkyazzentwatwa/drone-mesh-mapper |
| Local source path | `/Users/cypher/Documents/GitHub/drone-mesh-mapper` |
| Build profile | `cardputer_adv` |
| Extra SD paths | `/drone/` |
| Return path | Open the Launcher page, then press BtnA, Enter, or Space. |
| Package note | Cardputer ADV Remote ID drone scanner with WiFi/BLE detection, SD logging, and Cypher OS return support. |
| Use it when | You want a passive Remote ID field scanner on the Cardputer ADV. |

## Overview

Drone Mesh Mapper is the Cardputer ADV build of the passive Remote ID detector.
It listens for supported Remote ID WiFi/BLE broadcasts, shows a live dashboard,
emits JSON over USB serial, and logs detections to SD when a card is present.

## What It Does

- Passively scans WiFi Remote ID channels and supported BLE Remote ID payloads.
- Shows live hits, current channel, SD state, RSSI, IDs, and board status.
- Writes detection logs under `/drone/logs/` when SD logging is available.
- Ships with the `/drone/` SD folder contract for payloads and field logs.

Use only for passive monitoring where it is legal and authorized.

## Controls

- BtnA, `Tab`, `Enter`, `Space`, `.`, `/`, `S`, or `J`: next page.
- `Del`, `,`, `;`, `W`, or `K`: previous page.
- Return to Cypher OS: navigate to the `Launcher` page, then press BtnA,
  `Enter`, or `Space`.

## SD And Runtime Files

- Runtime folder: `/drone/`
- Detection log: `/drone/logs/detections.jsonl`
- CSV summary: `/drone/logs/remote_id_seen.csv`
- Payload seed: `/drone/payloads/remote_id_payload.json`
- Cypher OS app binary: `/cypher-puter/apps/drone-mesh-mapper.bin`

## Source Docs Used

- README.md from `/Users/cypher/Documents/GitHub/drone-mesh-mapper`
- docs/BOARD_PROFILES.md from `/Users/cypher/Documents/GitHub/drone-mesh-mapper`
- sd/README.md from `/Users/cypher/Documents/GitHub/drone-mesh-mapper`
