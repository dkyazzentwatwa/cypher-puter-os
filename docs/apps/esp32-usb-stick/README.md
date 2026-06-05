# ESP32 USB Stick

## Cypher OS Package

| Field | Value |
| --- | --- |
| Catalog slug | `esp32-usb-stick` |
| SD binary | `/cypher-puter/apps/esp32-usb-stick.bin` |
| Source repo | https://github.com/dkyazzentwatwa/cardputer-app-bundle |
| Local source path | `/Users/cypher/Documents/GitHub/new-cardputer-apps/Esp32-USB-Stick` |
| Build profile | `cardputer` |
| Extra SD paths | None required |
| Return path | Eject or unmount the USB disk from the host, then press `Fn+Del`. |
| Package note | Built from the public `cardputer-app-bundle` repo while the default local checkout remains `../new-cardputer-apps`. |

## Overview

ESP32 USB Stick exposes the Cardputer SD card as USB mass storage. It is
packaged as a Cypher OS app binary, but the whole SD card remains the runtime
storage surface.

## Return To Cypher OS

Unmount or eject the host-visible disk first, then press `Fn+Del` so the app can
set the launcher return flag and restart without risking host-side writes.
