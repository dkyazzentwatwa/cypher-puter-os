# Cardputer MPC

## Cypher OS Package

| Field | Value |
| --- | --- |
| Catalog slug | `cardputer-mpc` |
| SD binary | `/cypher-puter/apps/cardputer-mpc.bin` |
| Source repo | https://github.com/dkyazzentwatwa/cardputer-mpc |
| Local source path | `/Users/cypher/Documents/GitHub/cardputer-mpc` |
| Build profile | `cardputer` |
| Extra SD paths | `/cardputer-mpc/` |
| Return path | Press Shift+Q to return to Cypher OS. Lowercase q remains an MPC pad trigger. |
| Package note | MPC-style groovebox with SD-loaded samples and sequencing. |
| Use it when | You want a tiny groovebox with pads, samples, sequencing, and SD project files. |

## Overview

Cardputer MPC turns the Cardputer into a tiny groovebox: pads, samples, 16-step sequencing, live triggering, project save/load, and a small performance UI.

## What It Does

- Loads short mono PCM WAV one-shots from SD.
- Maps samples to Cardputer keyboard pads.
- Runs a 16-step sequencer with play, stop, record overdub, and step editing.
- Includes starter and 8-bit kits plus a demo groove.
- Shows pad, step, mixer, project, and waveform visualizer views.

## Controls

- Pads: `q w e r`, `a s d f`, `z x c v`, `1 2 3 4`.
- Space: play/stop. Enter: toggle record overdub.
- Tab: change view. `5`/`6` or `[`/`]`: previous/next step.
- `,`/`.`: previous/next pad. Shift + `,`/`.`: pad volume.
- `-`/`=`: master volume. Shift + `-`/`=`: BPM.
- Shift+S saves, `l` loads the demo groove, `k` cycles kits, backtick stops voices.

## SD And Runtime Files

- Runtime folder: `/cardputer-mpc/` on the SD card.
- Samples: `/cardputer-mpc/samples/`.
- Kits: `/cardputer-mpc/kits/starter.json` and `/cardputer-mpc/kits/8bit.json`.
- Projects: `/cardputer-mpc/projects/`.
- Cypher OS app binary: `/cypher-puter/apps/cardputer-mpc.bin`.

## Return To Cypher OS

Press `Shift+Q` to return to Cypher OS when launched from its SD catalog. Lowercase `q` remains a pad trigger.

## Source Docs Used

- README.md from /Users/cypher/Documents/GitHub/cardputer-mpc
- sdcard/cardputer-mpc/samples/README.md
- Cypher OS manifest notes
