# Cypher AirTag: Apple Find My / AirTag Detector Design

Date: 2026-09-17
Status: approved for implementation

## 1. Summary

Add a passive Apple Find My / AirTag detector to the Cypher OS catalog as a
new sibling app, **Cypher AirTag** (slug `cypher-airtag`, binary
`cypher-airtag.bin`). The app scans BLE advertisements on the M5Stack
Cardputer ADV, lists nearby Find My tags with proximity and status, raises an
alert when a *separated* tag stays with the user past a time threshold, offers
Geiger-style locate beeps for a selected tag, logs events to SD and USB serial,
and returns to the Cypher OS launcher.

### Goals

- Detect every Apple Offline Finding (Find My) advertiser: AirTags, third-party
  Find My accessories, AirPods, and other Apple devices in lost/off state.
- Distinguish **nearby** (owner seen within ~15 min) from **separated** mode.
- Alert once per presence window when a separated tag has been continuously
  present for a user-settable threshold (default 10 min).
- Locate mode: beep cadence follows RSSI so a hidden tag can be swept for.
- Log events as JSON lines to SD and over USB serial.
- Keep protocol logic host-testable, and keep the Cypher OS launcher untouched.

### Non-goals

- Samsung SmartTag, Tile, or Google Find Hub detection.
- Location-based "following" logic (the Cardputer has no GPS); presence is
  time-based only.
- Definitive AirTag-vs-accessory identification. Classification uses AirGuard's
  published status-byte heuristics and is labelled best-effort.
- Any active BLE traffic (connecting, pairing, spoofing). Scanning is passive.
- Launcher changes. Cypher OS stays small; this is an SD catalog app.

## 2. Context

Cypher OS is a launcher living in `ota_0`. Apps are separate sibling repos
built to `.bin` files by `tools/build-apps.sh`, cataloged in
`config/apps.json`, documented under `docs/apps/<slug>/README.md`, and copied
from SD into `ota_1` by the launcher. Flock You and Drone Mesh Mapper are the
closest existing field-detector apps and set the conventions this design
follows (passive scan, SD JSONL logs, serial JSON, return-to-launcher).

Sibling app repos are not checked out on the development Mac, so
`./tools/build-apps.sh` cannot regenerate the full committed `dist/` bundle
here. This design adds the catalog entry and build wiring now; the committed
release bundle is refreshed on the next full release build.

## 3. Repository layout (new sibling repo `../cypher-airtag`)

```
cypher-airtag/
  cypher-airtag.ino        # setup/loop only: constructs App and delegates to it
  sketch.yaml              # profile "cardputer-adv"
  src/core/                # pure C++17, no Arduino headers, compiles on the host
    findmy_adv.h/.cpp      #   raw Apple manufacturer bytes -> Advert
    tracker_registry.h/.cpp#   fixed table keyed by MAC
    follow_detector.h/.cpp #   alert rule + mute list
    format.h/.cpp          #   MAC / key hex / presence / ago string formatters
  src/device/              # Arduino / M5 glue
    app.h/.cpp             #   owns every module; drains sightings, runs periodic work, routes input
    ble_scanner.h/.cpp     #   NimBLE passive scan -> FreeRTOS queue of Sighting
    ui.h/.cpp              #   RADAR / DETAIL / ALERTS / SETTINGS pages, overlay
    input.h/.cpp           #   keyboard + BtnA -> InputEvent
    event_log.h/.cpp       #   JSONL -> SD, JSON -> Serial
    settings.h/.cpp        #   Preferences (NVS)
    sound.h/.cpp           #   alert chirps + locate beeps
    launcher_return.h      #   CypherPuterReturn.h when available, restart fallback
  test/host/
    harness.h              #   TEST()/EXPECT_* macros, main runner
    test_findmy_adv.cpp
    test_tracker_registry.cpp
    test_follow_detector.cpp
    test_format.cpp
  tools/
    run-host-tests.sh      #   clang++ -std=c++17 -Wall -Wextra -Werror src/core + test/host
    build.sh               #   arduino-cli compile --profile cardputer-adv, prints bin size
  README.md
```

`sketch.yaml` profile `cardputer-adv`:

- FQBN `m5stack:esp32:m5stack_cardputer:FlashSize=8M,PartitionScheme=default_8MB,CDCOnBoot=cdc,USBMode=hwcdc`
  (matches `CARDPUTER_FQBN` in `tools/build-apps.sh`).
- Platform `m5stack:esp32` from `https://static-cdn.m5stack.com/resource/arduino/package_m5stack_index.json`.
- Libraries pinned: `M5Cardputer (1.1.1)`, `M5Unified (0.2.14)`, `M5GFX (0.2.20)`,
  `NimBLE-Arduino (2.5.1)`. If the M5 pins fail to resolve against
  M5Cardputer 1.1.1 the implementer bumps M5Unified/M5GFX to the locally
  installed 0.2.21/0.2.29 and records the change in the app README.

The `.ino` includes core headers as `"src/core/findmy_adv.h"` etc. Arduino
compiles `src/` recursively; `test/` and `tools/` are never compiled for the
device.

## 4. Core units (`src/core`, no Arduino dependencies)

Time is always passed in as `uint32_t nowMs`; core never calls `millis()`.

### 4.1 `findmy_adv` — advertisement parser

Input: Apple manufacturer-specific data exactly as NimBLE delivers it
(`getManufacturerData()`), i.e. starting at the little-endian company ID.

```cpp
namespace findmy {
enum class Mode : uint8_t { Nearby, Separated };
enum class DeviceClass : uint8_t { AppleDevice = 0, AirTag = 1, FindMyAccessory = 2, AirPods = 3 };
enum class Battery : uint8_t { Full = 0, Medium = 1, Low = 2, Critical = 3 };

struct Advert {
  bool valid = false;
  Mode mode = Mode::Nearby;
  uint8_t status = 0;
  DeviceClass deviceClass = DeviceClass::AppleDevice;
  Battery battery = Battery::Full;
  uint8_t keyBits = 0;       // top two bits of key byte 0 (masked 0xC0)
  uint8_t keyTail[22] = {};  // public key bytes 6..27, separated mode only
};

Advert parse(const uint8_t* data, size_t len);
void assembleKey(const uint8_t mac[6], uint8_t keyBits, const uint8_t keyTail[22], uint8_t out[28]);
bool reconstructKey(const uint8_t mac[6], const Advert& adv, uint8_t out[28]);  // Separated only; calls assembleKey
DeviceClass deviceClassFromStatus(uint8_t status);  // (status >> 4) & 0x03
Battery batteryFromStatus(uint8_t status);          // (status >> 6) & 0x03
const char* deviceClassLabel(DeviceClass);          // "airtag" "findmy" "airpods" "apple"
const char* deviceClassShort(DeviceClass);          // "AT" "FM" "AP" "AD"
const char* batteryLabel(Battery);                  // "full" "medium" "low" "critical"
const char* modeLabel(Mode);                        // "near" "sep"
}
```

Parse algorithm:

1. `len < 4` or company ID != `4C 00` -> invalid.
2. Walk Apple TLVs from offset 2: `type = d[i]`, `tlen = d[i+1]`; a TLV that
   runs past `len` -> invalid (truncated).
3. First TLV with `type == 0x12`:
   - `tlen == 0x02`: Nearby. `status = d[i+2]`, `keyBits = d[i+3] & 0xC0`.
   - `tlen == 0x19`: Separated. `status = d[i+2]`, `keyTail = d[i+3 .. i+24]`,
     `keyBits = d[i+25] & 0xC0`, hint byte `d[i+26]` ignored.
   - any other `tlen` -> invalid.
   Battery and class are derived from `status`.
4. No `0x12` TLV -> invalid.

`reconstructKey`: `out[0] = (mac[0] & 0x3F) | keyBits`, `out[1..5] = mac[1..5]`,
`out[6..27] = keyTail`. Returns false for Nearby adverts. The MAC is the
printed (big-endian) byte order.

### 4.2 `tracker_registry` — who is around

```cpp
namespace findmy {
struct Sighting { uint8_t mac[6]; int8_t rssi; uint32_t ms; Advert adv; };

struct Entry {
  bool used;
  uint8_t mac[6];
  Mode mode; DeviceClass deviceClass; Battery battery; uint8_t status;
  bool hasKey; uint8_t keyBits; uint8_t keyTail[22];
  uint32_t firstSeenMs, lastSeenMs, presenceStartMs, lastUpdateLogMs;
  uint32_t advCount;
  int8_t rssiLast; float rssiEma;
  bool alerted;
};

struct ObserveResult { int index; bool isNew; bool modeChanged; bool presenceReset; Mode previousMode; };

class TrackerRegistry {
 public:
  static constexpr size_t kCapacity = 48;
  explicit TrackerRegistry(uint32_t gapToleranceMs = 120000, uint32_t lostAfterMs = 300000);
  ObserveResult observe(const Sighting& s, uint32_t nowMs);
  size_t expire(uint32_t nowMs, Entry* lostOut, size_t maxOut);  // removes + reports lost entries
  size_t size() const;
  size_t separatedCount() const;
  Entry* at(size_t slot);                 // nullptr if unused
  const Entry* at(size_t slot) const;
  Entry* find(const uint8_t mac[6]);
  size_t sortedByRssi(int* slotsOut, size_t maxOut) const;  // used slots, rssiEma desc
  uint32_t evictions() const;
};
}
```

Rules:

- `observe` on a new MAC fills a free slot (or evicts the used entry with the
  smallest `lastSeenMs` when full, incrementing `evictions`). New entries set
  `firstSeen = lastSeen = presenceStart = now`, `rssiEma = rssi`,
  `advCount = 1`, `alerted = false`.
- `observe` on a known MAC: if `now - lastSeen > gapTolerance` then
  `presenceStart = now`, `alerted = false`, `presenceReset = true`. Then
  `lastSeen = now`, `advCount++`, `rssiLast = rssi`,
  `rssiEma += 0.3f * (rssi - rssiEma)`. Mode, class, battery, status and key
  are refreshed from the advert; `modeChanged` reports a nearby/separated flip.
  A separated advert sets `hasKey = true` and stores the key tail; a nearby
  advert leaves a previously stored key in place.
- `expire` removes entries with `now - lastSeen >= lostAfter` and copies them
  to `lostOut` (up to `maxOut`) so the caller can log them.
- Slot indices are stable while an entry is used; the UI keeps a selected MAC
  rather than a slot index so eviction never selects the wrong tag.

### 4.3 `follow_detector` — the alert rule

```cpp
namespace findmy {
class FollowDetector {
 public:
  struct Alert { uint8_t mac[6]; uint32_t presenceMs; int8_t rssi; DeviceClass deviceClass; };
  static constexpr size_t kMuteCapacity = 8;
  void setThresholdMs(uint32_t ms);
  uint32_t thresholdMs() const;
  size_t evaluate(TrackerRegistry& reg, uint32_t nowMs, Alert* out, size_t maxOut);
  void mute(const uint8_t mac[6]);      // ring of 8; oldest overwritten
  bool isMuted(const uint8_t mac[6]) const;
};
}
```

`evaluate` visits every used entry and emits an alert (setting
`entry.alerted = true`) when all hold:
`mode == Separated`, `!alerted`, `!isMuted(mac)`,
`now - presenceStart >= threshold`. Nearby tags never alert. Because
`presenceReset` clears `alerted`, a tag alerts once per continuous presence
window and re-arms after a gap. Lowering the threshold at runtime causes
qualifying tags to alert on the next evaluation, which is intended.

## 5. Device units (`src/device`)

### 5.1 `ble_scanner`

- `bool begin()`: `NimBLEDevice::init("")`, get the scan object, passive scan,
  interval 100 ms, window 100 ms (100% duty), duplicate filter off,
  `setMaxResults(0)`, `start(0 /* forever */, false, true)`. `onScanEnd`
  restarts the scan.
- `onResult`: if the device has manufacturer data, call `findmy::parse` on
  it. If valid, build a `Sighting` (MAC copied into printed byte order, RSSI,
  `millis()`, advert) and `xQueueSend(queue, &s, 0)` onto a 32-slot FreeRTOS
  queue. On a full queue the sighting is dropped and `dropped` increments.
  Nothing else runs on the NimBLE task.
- `bool poll(Sighting& out)`: `xQueueReceive(queue, &out, 0)`.
- Counters: `received` (valid adverts queued), `dropped`.

### 5.2 `input`

Mirrors the launcher's `readInput()` so the key map matches Cypher OS:

| Action | Keys |
| --- | --- |
| up | `;` `,` `w` `k` |
| down | `.` `/` `s` `j` |
| left (prev page / cycle value) | `a` `h` |
| right (next page / cycle value) | `d` `l` |
| select | Enter, BtnA |
| back | Del, Tab, `` ` ``, `q` |
| mute | `m` |
| locate toggle | Space |

`InputEvent { up, down, left, right, select, back, mute, space, any }`,
populated from `M5Cardputer.Keyboard.keysState()` on `isChange() && isPressed()`
plus `M5Cardputer.BtnA.wasClicked()`.

### 5.3 `ui`

Display 240x135, rotation 1, M5GFX, palette copied from the launcher's default
"Neon Grid" theme: bg `0x0000`, panel `0x0841`, text `0xFFFF`, dim `0x9CD3`,
accent `0x07FF`, warn `0xFD20`, bad `0xF800`, good `0x07E0`, header `0x0186`,
footer `0x1082`, selected `0x034F`, selected text `0x0000`.

Header on every page: `AIRTAG <PAGE>` on the left and `<n> tags <s> sep` on the
right. Footer on every page: the page's key hints on the left; on the right
`SD!` in warn colour when SD logging is enabled but unavailable, a scan
spinner (`X` in bad colour if BLE failed), and the battery percentage.

Pages (left/right cycle RADAR -> ALERTS -> SETTINGS; DETAIL is entered from
RADAR or ALERTS with select and left with back; ABOUT is entered from
SETTINGS and left with back). Rows are 16 px tall, six visible per page:

**RADAR** — used entries sorted by `rssiEma` descending, 6 rows visible,
scrolling with the selection. Row format:
`<!> <AT|FM|AP|AD> <last 2 MAC bytes hex> <near|sep> <5-cell RSSI bar> <dBm> <presence m/s>`.
The RSSI bar lights `clamp(round((rssiEma + 95) / 10), 0, 5)` cells. Presence
prints as `<n>s` under 60 s, else `<n>m`. `!` marks `alerted`. Rows unseen for more than 30 s draw in dim colour;
separated rows draw the mode in warn colour. Footer: `↑↓ select  Enter detail  ←→ page`.
Back on RADAR opens a confirm dialog "Return to Cypher OS?" — select confirms,
back cancels.

**DETAIL / LOCATE** — for the selected MAC: full MAC, class label + battery,
mode, raw status (`0x..`), first seen / last seen as `Xm Ys ago`, advert
count, first 16 hex chars of the reconstructed key (or `no key (nearby)`),
a large RSSI bar with dBm. Space toggles Locate; `LOCATE` shows in the header
while active and beeps run per §5.6. `m` mutes the tag (logs `mute`, clears
its alert flag). If the entry expires while shown, the page reads
`lost — press back`.

**ALERTS** — entries with `alerted == true`, most recent alert first (the
`.ino` keeps a 16-entry ring of alert MACs + times). Row:
`<AT..> <id> <presence> <dBm>`. Select opens DETAIL; `m` mutes. Empty state:
`No alerts. Separated tags present for ≥ <threshold> min appear here.`

**SETTINGS** — rows: `Alert threshold` (5/10/15/30/60 min), `Sound`,
`SD log`, `Serial JSON`, `Return to Cypher OS`, `About`. Up/down select;
select cycles the value (threshold wraps 5→10→15→30→60→5) and saves
immediately. Left/right always switch pages, on every page. `Return to Cypher OS`
opens the same confirm dialog as RADAR back. `About` shows version, session
number, queue drops, evictions, SD state, free heap.

**Alert overlay** — when `evaluate` returns alerts, a centred panel appears
over any page: line 1 `SEPARATED TAG PRESENT <presence>m`, line 2
`<class> <id>  <dBm> dBm`, line 3 `Enter view · M mute · Del dismiss`.
Select opens DETAIL for that tag, `m` mutes it, back dismisses. Multiple alerts
queue; the overlay shows the newest.

Redraw: the `.ino` marks the UI dirty on input, on registry changes, and on a
250 ms timer; `ui.draw()` renders only when dirty. Drawing uses a full-screen
sprite when PSRAM/heap allows, else direct drawing with per-page clears.

### 5.4 `event_log`

`begin()` mounts SD with the launcher's pins (SCK 40, MISO 39, MOSI 14,
CS 12, 25 MHz) and creates `/cypher-airtag/logs/` if missing. Serial is
`Serial` (USB CDC, 115200) with `setTxTimeoutMs(0)` so an unattached host never
blocks.

File: `/cypher-airtag/logs/findmy.jsonl`, append mode. Before each append, if
the file size exceeds 4 MB, `findmy.1.jsonl` is removed and the current file
is renamed to it.

Every line is one JSON object with `ev`, `t` (ms since boot) and `session`
(NVS boot counter). Events:

| `ev` | Extra fields |
| --- | --- |
| `boot` | `fw`, `sd` (state label: `off`, `mounted`, `missing`, `write_error`), `thresh_min` |
| `seen` | `mac`, `cls`, `mode`, `rssi`, `batt`, `status` (`"0x10"`), `key` (56 hex, separated only) |
| `update` | `mac`, `mode`, `rssi_ema`, `advs`, `presence_s` — once per 60 s per present tag |
| `mode` | `mac`, `from`, `to` |
| `alert` | `mac`, `cls`, `presence_s`, `rssi` |
| `mute` | `mac` |
| `lost` | `mac`, `presence_s`, `advs` |
| `sd` | `state` (`off`, `mounted`, `missing`, `write_error`) |

Lines are formatted with `snprintf` into a 320-byte stack buffer; no heap
allocation per line. SD write failures set the SD state to `write_error`, stop
further SD writes, and are shown in the header/About until the user toggles SD
log off and on (which retries `begin()`).

### 5.5 `settings`

Preferences namespace `cyairtag`:

| Key | Type | Default |
| --- | --- | --- |
| `thresh` | u8 minutes (5/10/15/30/60) | 10 |
| `sound` | bool | true |
| `sdlog` | bool | true |
| `serial` | bool | true |
| `boots` | u32 | incremented at boot, used as `session` |

Loaded once in `setup()`, each field written on change.

### 5.6 `sound`

`M5Cardputer.Speaker`. Alert: three 1200 Hz / 80 ms chirps 120 ms apart.
Locate: 880 Hz / 30 ms beeps with period linearly mapped from the tag's
`rssiEma` clamped to [-90, -40] dBm onto [1500, 150] ms; when the tag has not
been seen for 5 s the period holds at 1500 ms. All sound is skipped when the
sound setting is off.

### 5.7 `launcher_return.h`

```cpp
#if __has_include(<CypherPuterReturn.h>)
#include <CypherPuterReturn.h>
inline void returnToLauncher() { CypherPuter::returnToLauncher(250); }
#else
inline void returnToLauncher() { delay(250); ESP.restart(); }
#endif
```

The Cypher OS build passes `-I${RETURN_LIB}/src`, so the real one-shot return
is used there; a standalone build falls back to a restart.

## 6. Main loop and data flow

```
NimBLE host task:  onResult -> findmy::parse -> valid? -> xQueueSend(Sighting)
loop():
  M5Cardputer.update(); input = readInput();
  while (scanner.poll(s)):
     r = registry.observe(s, now)
     if r.isNew        -> log seen
     if r.modeChanged  -> log mode
     dirty = true
  every 1 s:  registry.expire(now) -> log lost for each; detector.evaluate() -> alerts:
              log alert, push to alert ring, show overlay, alert chirps; dirty = true
  every 60 s per entry (lastUpdateLogMs): log update
  locate tick (if active): schedule next beep from selected entry's rssiEma
  handleInput(input); if (dirty || 250 ms elapsed) ui.draw()
  delay(10)
```

All registry, detector, log and UI work happens on the Arduino loop task. The
NimBLE task only parses and enqueues.

## 7. Error handling

| Condition | Behaviour |
| --- | --- |
| SD missing at boot / write error | Logging to SD disabled, `SD!` in header, state in About, `sd` event on serial; SD toggle retries |
| Queue full | Sighting dropped, `dropped` counter in About |
| Registry full | Oldest-seen entry evicted, `evictions` counter in About |
| NimBLE init fails | Error page with message; Settings page still reachable so Return to Cypher OS works |
| Malformed / non-Find-My advert | `parse` returns invalid; dropped on the NimBLE task |
| Selected tag expires | DETAIL shows `lost — press back`; Locate stops |
| USB serial unattached | `setTxTimeoutMs(0)`; writes drop instead of blocking |

Nothing in the loop blocks longer than an SD append (a few ms); there is no
watchdog exposure.

## 8. Cypher OS integration (this repo)

- `config/apps.json`: new entry after Drone Mesh Mapper:
  name `Cypher AirTag`, slug `cypher-airtag`, binary `cypher-airtag.bin`,
  repo_url `https://github.com/dkyazzentwatwa/cypher-airtag`,
  local_default_path `../cypher-airtag`, build_profile `cardputer-adv`,
  sd_paths `["/cypher-airtag/"]`,
  return_to_launcher `Choose Return to Cypher OS on the Settings page, or press backtick on the Radar page and confirm with Enter.`,
  public_release `true`, status `ready`,
  notes `Cardputer ADV passive Apple Find My / AirTag detector with following alerts, locate beeps, SD JSONL logs, and Cypher OS return support.`
- `tools/build-apps.sh`: add `cypher-airtag` to the slug allowlist,
  `CYPHER_AIRTAG_ROOT="${CYPHER_OS_CYPHER_AIRTAG_DIR:-${WORKSPACE_ROOT}/cypher-airtag}"`,
  `CYPHER_AIRTAG_STATUS`, `set_status`/`get_status`/`mark_failed` cases,
  `build_cypher_airtag()` (`arduino-cli compile --profile cardputer-adv
  --output-dir "${out}" --build-property "compiler.cpp.extra_flags=-I${RETURN_LIB}/src" "${src}"`),
  `run_build "cypher-airtag" build_cypher_airtag` after Drone Mesh Mapper, the
  env pass-through lines, and the final ready check.
- `tools/build-report.py`: `"cypher-airtag": ("CYPHER_AIRTAG_STATUS", "CYPHER_AIRTAG_ROOT")`
  and an SD note line for `/cypher-airtag/logs/`.
- `tools/package-sd.sh`: `mkdir -p "${SD_ROOT}/cypher-airtag/logs"`.
- `tools/flash-app-slot.sh` (new dev helper): writes any app `.bin` into the
  `app1` slot at `0x170000` with the ESP32 core's bundled esptool and sends
  `launch` to the launcher over serial. Documented in
  `docs/BUILDING_AND_PACKAGING.md`.
- Docs: `docs/apps/cypher-airtag/README.md` (same table layout as the Drone
  Mesh Mapper page: package table, overview, what it does, controls, SD and
  runtime files, return path, on-device test checklist, legal note);
  one-line additions to `docs/README.md`, `docs/APP_CATALOG.md`, the README
  lineup table and env override lists (README + BUILDING_AND_PACKAGING), and
  AGENTS.md's app status list.
- `dist/` is not modified in this work.

## 9. Testing

### 9.1 Host tests (run first, test-driven)

`tools/run-host-tests.sh` builds `src/core/*.cpp` and `test/host/*.cpp` with
`clang++ -std=c++17 -Wall -Wextra -Werror -Isrc/core` and runs the binary.

- parser: nearby form; separated form; chained Apple TLVs before `0x12`;
  wrong company ID; truncated TLV; unknown `0x12` length; battery and class
  decoding for all four values each; key reconstruction; labels.
- registry: new entry; update refreshes RSSI EMA/count/mode; gap beyond
  tolerance resets presence and clears `alerted`; gap within tolerance does
  not; eviction of oldest when full; `expire` reports and removes lost entries;
  `sortedByRssi` order; `find` by MAC.
- detector: fires at threshold, not before; never for nearby; once per
  presence window; re-arms after a gap; honours mute; mute ring overwrites
  oldest; threshold change takes effect on next evaluate.

### 9.2 Device build

`tools/build.sh` in the sibling repo (standalone) and
`./tools/build-apps.sh --app cypher-airtag` from this repo (integration).
Because `build-apps.sh` wipes `dist/apps`, the integration build is followed
by `git checkout -- dist` so the committed bundle is unchanged.
`python3 tools/validate-catalog.py config/apps.json` must pass.

### 9.3 On-device (Cardputer ADV on `/dev/cu.usbmodem*`)

Dev loop: `tools/flash-app-slot.sh build/cypher-airtag.ino.bin` writes the app
into `app1` and sends `launch`; the launcher in `app0` is untouched. Checklist
(also recorded in the app README):

1. Boot: header shows scan indicator; serial prints the `boot` line.
2. AirTag near its paired iPhone: row shows `AT`, `near`, RSSI updates.
3. iPhone in airplane mode for ~15 min: row flips to `sep`, `mode` line logged.
4. Threshold set to 5 min: overlay + three chirps fire once; `alert` logged;
   ALERTS lists the tag; dismissing does not re-alert.
5. `m` on the tag: `mute` logged; no further alert for that MAC.
6. Locate: beep period shortens as the tag approaches.
7. Remove the tag for >5 min: `lost` logged, row disappears.
8. SD: `/cypher-airtag/logs/findmy.jsonl` contains the lines above with
   increasing `t` and a constant `session`.
9. Settings persist across a power cycle.
10. Return to Cypher OS from Settings and via backtick-on-Radar lands in the
    launcher with its "Returned To Launcher" message.

## 10. Version control

- `../cypher-airtag`: `git init`, commits per implementation task, README with
  build/test/dev-loop instructions. Publishing to GitHub is the user's call.
- This repo: one integration commit on a feature branch (catalog, scripts,
  docs, spec). No `dist/` changes.

## 11. Protocol caveats (documented in the app README)

- Find My identity is heuristic: the MAC and key rotate together, roughly
  every 15 min in nearby mode and every 24 h in separated mode, so a tag seen
  across a rotation appears as a new entry.
- Device class comes from status-byte bits 5–4 as used by AirGuard; Apple does
  not document it. Battery comes from bits 7–6.
- A powered-off iPhone, iPad, Mac, or AirPods case also advertises Offline
  Finding and shows up as `AD`/`AP`.
- Passive listening only. Use where such monitoring is legal and authorized.
