# Launcher Model

Cypher OS feels like a small app deck, but it stays within how ESP32 firmware
actually boots.

## The Short Version

The Cardputer does not execute apps directly from the SD card. The SD card is a
storage catalog. The launcher installs the selected app `.bin` into the app
partition and then reboots into that app.

```text
Launcher in ota_0
      |
      | reads /cypher-puter/apps/apps.json
      v
Selected .bin on SD
      |
      | copied into ota_1
      v
Reboot into installed app
```

## Partitions

The launcher uses the custom Cardputer ADV layout in `partitions.csv`:

| Partition | Role |
| --- | --- |
| `ota_0` / `app0` | Cypher OS launcher. |
| `ota_1` / `app1` | Installed SD app slot. |
| `otadata` | ESP32 OTA boot selection state. |
| LittleFS data partition | Shared runtime data used by apps such as Cypher Drive. |

The launcher remains installed while apps are swapped through the app slot.

## App Binaries

Use normal sketch app `.bin` files. The launcher rejects common wrong inputs:

- Merged flash images.
- Bootloader `.bin` files.
- Partition-table `.bin` files.
- Binaries larger than the app slot.
- Missing files referenced by `apps.json`.

The packaged SD app binaries live here:

```text
/cypher-puter/apps/
```

The public catalog file lives here:

```text
/cypher-puter/apps/apps.json
```

## Return To Launcher

Supported apps include a small return helper. When the user chooses the app's
return path, the app:

1. Sets a one-shot launcher return flag.
2. Selects the launcher partition as the next boot target.
3. Restarts.

The one-shot flag prevents the launcher from immediately auto-launching the app
again after a return.

## Boot Behavior

The launcher can either stop at the menu or try to auto-launch the installed app
on boot. If an app returns to the launcher, auto-launch is paused for that
return so the user can pick the next action.

## Serial Commands

Open the Cardputer serial monitor at the board's current USB serial port, then
type:

```text
help
status
apps
reload
launch
erase
install <slug>
```

Useful examples:

```text
status
apps
install cypher-desk
launch
erase
```

`erase` invalidates the installed app slot. It does not remove the Cypher OS
launcher.
