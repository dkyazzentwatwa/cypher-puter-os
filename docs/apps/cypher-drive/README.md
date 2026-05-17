# Cypher Drive

## Overview

Cypher Drive is the Cardputer ADV build of the portable ESP32-S3 wireless and HID utility firmware. Inside Cypher OS it works as the payload, scan, capture, and storage-heavy tool in the app deck.

## What It Does

- WiFi and BLE scanning with local status views.
- USB HID keyboard payload launcher behavior for prepared macros.
- Captive portal templates and SD-backed capture browsing in the upstream firmware.
- System information, display diagnostics, and session logging.
- LittleFS-backed log/config storage when launched from Cypher OS.

Use payload, scan, and capture workflows only on systems you own or are
authorized to test.

## Controls

- Cardputer keyboard and menu controls are profile-specific in the app firmware.
- Use the app menu to navigate scans, payloads, storage, diagnostics, and utilities.
- Return behavior depends on the Cypher OS packaged build and app-side launcher return support.

## SD And Runtime Files

- Shared data partition: LittleFS for Cypher Drive log/config storage.
- Cypher OS app binary: `/cypher-puter/apps/cypher-drive.bin`.

## Return To Cypher OS

Use the app-side launcher return path when present in the packaged build. Cypher OS keeps the launcher in `ota_0` and installs this app into `ota_1` before launch.

## Source Docs Used

- README.md from /Users/cypher/Documents/GitHub/cypher-drive
- Cypher OS app manifest notes
