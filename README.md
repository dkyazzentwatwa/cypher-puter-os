# Cypher OS

Arduino CLI-only SD app launcher for the M5Stack Cardputer ADV.

Cypher OS keeps a small launcher resident on the Cardputer and installs
selected app `.bin` files from SD into the large app partition. ESP32 firmware
cannot execute directly from SD, so this gives the practical workflow we want:
swap Cardputer apps from a local SD catalog instead of USB reflashing every
time.

## Hardware

- M5Stack Cardputer ADV
- FAT32 SD card, preferably 32 GB or smaller
- Apps stored under `/cypher-puter/apps`

## Build The Launcher

```bash
cd /Users/cypher/Documents/GitHub/cypher-puter-os
arduino-cli compile --profile adv .
```

Or:

```bash
./tools/build-launcher.sh
```

The canonical profile is in `sketch.yaml`:

```text
m5stack:esp32:m5stack_cardputer:FlashSize=8M,PartitionScheme=custom,CDCOnBoot=cdc,USBMode=hwcdc
```

## Flash The Launcher

Use the touch-first Cardputer flow:

```bash
arduino-cli board list
./tools/flash-launcher.sh /dev/cu.usbmodemXXXX
```

If you omit the port, the script uses the first `/dev/cu.usbmodem*` port it
finds, touches it at 1200 baud, waits for re-enumeration, then uploads with the
`adv` profile.

## Build Apps For SD

```bash
./tools/build-apps.sh
./tools/package-sd.sh
```

Then copy the contents of:

```text
/Users/cypher/Documents/GitHub/cypher-puter-os/dist/sd-card
```

to the root of a FAT32 SD card.

Expected SD layout:

```text
/cypher-puter/apps/apps.json
/cypher-puter/apps/cardputer-games.bin
/cypher-puter/apps/cardputer-mpc.bin
/cypher-puter/apps/cypher-desk.bin
/cypher-puter/apps/cypher-chat.bin
/cypher-puter/apps/cypher-drive.bin
/cypher-puter/apps/flock-you.bin
/cypher-puter/apps/wiretap-32-cardputer.bin
/cypher-puter/apps/<cardputer-game-os-game>.bin
/cardputer-mpc/
/cardputer-game-os/saves/
```

The catalog also imports individual game `.bin` files from
`/Users/cypher/Documents/GitHub/cardputer-game-os`. The nested Game OS launcher
itself is not packaged because Cypher OS already owns the launcher partition.
Cypher Chat is built from
`/Users/cypher/Documents/GitHub/cypher-chat/cypher-chat-firmware` with
`BOARD_PROFILE_CARDPUTER_ADV`; its mesh protocol is secure-only `0x02`, so all
fleet devices need matching firmware.
The catalog also includes `starbeam-cardputer` as a visible placeholder marked
`needs_cardputer_port`. It will not install until it has a real Cardputer ADV
build.

## Controls

- `,` or `;`: up
- `.` or `/`: down
- `W/S` and `K/J`: up/down alternatives
- `Enter` or BtnA: select
- Backtick, `Del`, `Tab`, or `Q`: back
- `R`: reload SD catalog
- In packaged apps, use the app's **Return to Launcher** item or `Del/Q` where
  shown. The app restarts, sets a one-shot return flag, and the launcher stays
  on the menu instead of auto-launching again.
- Cardputer MPC: use `Shift+Q` to return to Cypher OS. Lowercase `q` remains an
  MPC pad trigger.
- Flock You: open the mini menu, cycle to `HOME`, then press up/down to return.
- WireTap-32: choose `Launcher` from the main menu, or type `launcher` /
  `return` over serial.

Serial monitor commands:

```text
help
status
apps
reload
launch
erase
install <slug>
```

## Notes

- Use sketch app `.bin` files, not merged flash images.
- The launcher rejects oversized bins and merged images before writing.
- The shared data partition is LittleFS so Cypher Drive can mount its log/config
  storage when launched from this OS.
- `Boot behavior` can auto-try the installed app on power-up or always stop at
  the launcher menu.
- The launcher uses a compact local OTA-slot model: launcher in `ota_0`,
  selected app in `ota_1`, then software restart for the handoff.
