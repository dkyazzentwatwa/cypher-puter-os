# WireTap-32 Cardputer

## Cypher OS Package

| Field | Value |
| --- | --- |
| Catalog slug | `wiretap-32-cardputer` |
| SD binary | `/cypher-puter/apps/wiretap-32-cardputer.bin` |
| Source repo | https://github.com/dkyazzentwatwa/WireTap-32 |
| Local source path | `/Users/cypher/Documents/GitHub/WireTap-32` |
| Build profile | `cardputer-adv-ext-bench` |
| Extra SD paths | None required beyond `/cypher-puter/apps/`. |
| Return path | Choose Launcher from the main menu, or type launcher / return over serial. |
| Package note | Cardputer ADV EXT bench build with return-to-launcher support. |
| Use it when | You want an EXT-header electronics bench companion for protocol and GPIO workflows. |

## Overview

WireTap-32 Cardputer is the electronics bench companion app in the Cypher OS deck. It brings protocol tools, GPIO controls, and serial-first workflows to the Cardputer ADV EXT header.

## What It Does

- I2C scan, ping, register read/write, dump, monitor, EEPROM shell, and recovery helpers.
- SPI transfers, configurable mode/order/frequency, EEPROM shell, and SPI flash ID/read helper.
- UART TX/RX, auto-baud scan, bridge mode, AT helper, and periodic spam mode.
- GPIO digital I/O, ADC, PWM, pulse/frequency checks, and ASCII waveform capture.
- Cardputer ADV EXT connector mapping for bench use with 3.3V target signals.

Use these bench tools only on boards and circuits you own or are authorized to
inspect. Check voltage levels before connecting the EXT header.

## Controls

- Cardputer path accepts arrows, HID arrows, `WASD`, `HJKL`, and punctuation for browsing.
- `Enter`, `Space`, or BtnA select.
- `Del`, `Tab`, `Q`, backtick, or `B` act as back or launcher-return keys in the Cardputer path.
- Serial commands remain central for bench workflows.

## SD And Runtime Files

- Cypher OS app binary: `/cypher-puter/apps/wiretap-32-cardputer.bin`.
- No required SD data folder is needed for the core bench companion workflow.

## Return To Cypher OS

Choose `Launcher` from the main menu, or type `launcher` / `return` over serial.

## Source Docs Used

- README.md from /Users/cypher/Documents/GitHub/WireTap-32
- USAGE.md and DEMOS.md from /Users/cypher/Documents/GitHub/WireTap-32
- Cypher OS controls notes
