# Cypher Chat

## Overview

Cypher Chat is the secure-only mesh communication app in the Cypher OS catalog. The packaged Cardputer ADV build comes from the unified `cypher-chat-firmware` sketch.

## What It Does

- ESP-NOW mesh chat with encrypted protocol `0x02`.
- AES-256-GCM payload encryption using a shared passphrase.
- Cardputer ADV display and keyboard profile through `BOARD_PROFILE_CARDPUTER_ADV`.
- USB/BLE terminal access for local setup and commands in the upstream firmware.
- Emergency/runtime mesh features from the unified firmware stack.

## Controls

- Cardputer keys navigate the local UI and message screens in the packaged profile.
- Terminal commands include `status`, `peers`, `send 1`, and `emergency` in the unified firmware docs.
- All fleet devices must run matching secure-only firmware to communicate.

## SD And Runtime Files

- Cypher OS app binary: `/cypher-puter/apps/cypher-chat.bin`.
- Canonical app source: `/Users/cypher/Documents/GitHub/cypher-chat/cypher-chat-firmware`.
- Default starter passphrase exists only for convenience and should be changed before real use.

## Return To Cypher OS

Use Menu -> System -> Return to launcher when available in the Cardputer ADV build. This lets the app restart back into Cypher OS instead of staying as a one-shot launched firmware.

## Source Docs Used

- cypher-chat-firmware/README.md
- top-level Cypher Chat README.md
- Cypher OS package notes
