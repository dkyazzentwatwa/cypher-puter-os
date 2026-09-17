# Cypher AirTag

## Cypher OS Package

| Field | Value |
| --- | --- |
| Catalog slug | `cypher-airtag` |
| SD binary | `/cypher-puter/apps/cypher-airtag.bin` |
| Source repo | https://github.com/dkyazzentwatwa/cypher-airtag |
| Local source path | `/Users/cypher/Documents/GitHub/cypher-airtag` |
| Build profile | `cardputer-adv` |
| Extra SD paths | `/cypher-airtag/` (logs are created at runtime) |
| Return path | Choose Return to Cypher OS on the Settings page, press backtick on the Radar page and confirm with Enter, or type `return` over serial. |
| Package note | Cardputer ADV passive Apple Find My / AirTag detector with following alerts, locate beeps, SD JSONL logs, and Cypher OS return support. |
| Use it when | You want to see which Find My tags are around you, find one hidden nearby, or get told when a separated tag keeps travelling with you. |

## Overview

Cypher AirTag listens passively for Apple Offline Finding (Find My) BLE
advertisements: AirTags, third-party Find My accessories, AirPods, and Apple
devices in lost or powered-off state. It never connects to or transmits at any
device.

## What It Does

- Lists nearby Find My advertisers nearest-first with class, mode, signal bar,
  dBm, and how long each has been continuously present.
- Tells **nearby** (owner seen within ~15 minutes) from **separated** adverts,
  the form Apple and AirGuard use for unwanted-tracker alerts.
- Raises an alert with an on-screen overlay and three chirps when a separated
  tag has been continuously present for the alert threshold (default 10 min).
- Locate mode: beeps faster as the selected tag's signal gets stronger.
- Logs JSON lines to `/cypher-airtag/logs/findmy.jsonl` on SD and over USB
  serial at 115200 baud.

Class labels (`AT` AirTag, `FM` Find My accessory, `AP` AirPods, `AD` other
Apple device) and battery level come from undocumented status-byte bits and
are best-effort.

## Controls

The key map matches the Cypher OS launcher.

| Action | Keys |
| --- | --- |
| Move selection | `;` `,` `w` `k` up, `.` `/` `s` `j` down |
| Switch page (Radar, Alerts, Settings) | `a` `h` left, `d` `l` right |
| Open detail / change a setting | `Enter` or BtnA |
| Back / dismiss | `Del`, `Tab`, backtick, `q` |
| Locate beeps (detail page) | `Space` |
| Mute a tag's alerts | `m` |

When an alert overlay is showing: `Enter` opens the tag, `m` mutes it, `Del`
dismisses it.

## SD And Runtime Files

- Log: `/cypher-airtag/logs/findmy.jsonl` (rotates once to `findmy.1.jsonl` at 4 MB).
- Events: `boot`, `seen`, `update` (every 60 s per present tag), `mode`,
  `alert`, `mute`, `lost`, `sd`. Times are milliseconds since boot; `session`
  is a boot counter kept in NVS.
- Settings (threshold, sound, SD log, serial JSON) persist in NVS.
- Cypher OS app binary: `/cypher-puter/apps/cypher-airtag.bin`.

## Return To Cypher OS

Settings → Return to Cypher OS, or press backtick on the Radar page and confirm
with Enter. Over USB serial, `return` or `launcher` does the same; `status`
prints a JSON summary and `list` dumps the tracked tags.

## Notes

- Tag identity rotates with the tag's key (about every 15 min in nearby mode,
  daily in separated mode), so one tag can appear as a new entry after a
  rotation.
- There is no GPS, so "following" means continuously present in time, not
  across locations.
- Passive listening only. Use where such monitoring is legal and authorized.

## Source Docs Used

- README.md from `/Users/cypher/Documents/GitHub/cypher-airtag`
- Cypher OS README controls
