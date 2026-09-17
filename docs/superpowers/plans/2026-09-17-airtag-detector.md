# Cypher AirTag Detector Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a passive Apple Find My / AirTag detector as a new Cypher OS catalog app (`cypher-airtag`) with a following alert, locate beeps, SD/serial JSON logging and launcher return.

**Architecture:** A new sibling Arduino sketch repo `../cypher-airtag`. `src/core/` is pure C++17 (parser, registry, follow detector, formatters) compiled and unit-tested on the Mac with clang++; `src/device/` is the Arduino/M5/NimBLE glue; `src/device/app.*` owns every module and the page state machine so the `.ino` is four lines. This repo gets the catalog entry, build-script wiring, docs, and a dev helper that flashes any app into the launcher's app slot.

**Tech Stack:** Arduino CLI 1.5.1, `m5stack:esp32` core 3.3.9, M5Cardputer 1.1.1 / M5Unified 0.2.14 / M5GFX 0.2.20, NimBLE-Arduino 2.5.1, FreeRTOS queue, Preferences (NVS), SD (SPI), clang++ for host tests, bash/python3 tooling.

Spec: `docs/superpowers/specs/2026-09-17-airtag-detector-design.md`.

---

## Conventions used in every task

- `APP=/Users/cypher/Documents/GitHub/cypher-airtag` (new sibling repo), `OS=/Users/cypher/Documents/GitHub/cypher-puter-os` (this repo, branch `feat/cypher-airtag`).
- Host tests: `cd $APP && tools/run-host-tests.sh` — must print `N tests, 0 failures`.
- Device build: `cd $APP && tools/build.sh` — must end with `[build] ok` and a size line.
- Every commit message ends with a blank line and `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.
- Never run `./tools/build-apps.sh` in `$OS` without following it with `git checkout -- dist` (it wipes `dist/apps`).

## File map

| File | Responsibility |
| --- | --- |
| `$APP/cypher-airtag.ino` | construct `App`, delegate `setup`/`loop` |
| `$APP/sketch.yaml` | `cardputer-adv` profile with pinned libraries |
| `$APP/src/core/findmy_adv.{h,cpp}` | Apple manufacturer bytes → `Advert`; key assembly; labels |
| `$APP/src/core/format.{h,cpp}` | MAC / key hex / presence / ago strings |
| `$APP/src/core/tracker_registry.{h,cpp}` | fixed table of tags keyed by MAC |
| `$APP/src/core/follow_detector.{h,cpp}` | alert rule + mute ring |
| `$APP/src/device/settings.{h,cpp}` | NVS-backed settings |
| `$APP/src/device/sound.{h,cpp}` | alert chirps, locate beeps (non-blocking) |
| `$APP/src/device/input.{h,cpp}` | keyboard/BtnA → `InputEvent` |
| `$APP/src/device/launcher_return.h` | Cypher OS return with standalone fallback |
| `$APP/src/device/version.h` | firmware version string |
| `$APP/src/device/ble_scanner.{h,cpp}` | NimBLE passive scan → FreeRTOS queue |
| `$APP/src/device/event_log.{h,cpp}` | JSONL to SD + Serial |
| `$APP/src/device/ui.{h,cpp}` | rendering of all pages/overlays |
| `$APP/src/device/app.{h,cpp}` | owns modules, loop, input routing |
| `$APP/test/host/*` | harness + unit tests for `src/core` |
| `$APP/tools/run-host-tests.sh`, `tools/build.sh` | test/build entry points |
| `$APP/README.md` | build, controls, log format, dev loop, checklist |
| `$OS/config/apps.json` | catalog entry |
| `$OS/tools/build-apps.sh`, `tools/build-report.py`, `tools/package-sd.sh` | build wiring |
| `$OS/tools/flash-app-slot.sh` | dev helper: write a `.bin` into `app1`, send `launch` |
| `$OS/docs/apps/cypher-airtag/README.md`, `docs/README.md`, `docs/APP_CATALOG.md`, `docs/BUILDING_AND_PACKAGING.md`, `README.md`, `AGENTS.md` | docs |

---

### Task 1: Scaffold the sibling repo, test harness, and tool scripts

**Files:**
- Create: `$APP/sketch.yaml`, `$APP/.gitignore`, `$APP/test/host/harness.h`, `$APP/test/host/test_main.cpp`, `$APP/tools/run-host-tests.sh`, `$APP/tools/build.sh`, `$APP/cypher-airtag.ino` (placeholder that compiles), `$APP/README.md` (stub)

- [ ] **Step 1: Create the repo and directories**

```bash
mkdir -p /Users/cypher/Documents/GitHub/cypher-airtag/{src/core,src/device,test/host,tools}
cd /Users/cypher/Documents/GitHub/cypher-airtag && git init -q -b main && echo ok
```

- [ ] **Step 2: Write `sketch.yaml`**

```yaml
profiles:
  cardputer-adv:
    fqbn: m5stack:esp32:m5stack_cardputer:FlashSize=8M,PartitionScheme=default_8MB,CDCOnBoot=cdc,USBMode=hwcdc
    platforms:
      - platform: m5stack:esp32
        platform_index_url: https://static-cdn.m5stack.com/resource/arduino/package_m5stack_index.json
    libraries:
      - M5Cardputer (1.1.1)
      - M5Unified (0.2.14)
      - M5GFX (0.2.20)
      - NimBLE-Arduino (2.5.1)

default_profile: cardputer-adv
```

- [ ] **Step 3: Write `.gitignore`**

```gitignore
.DS_Store
build/
*.elf
*.map
```

- [ ] **Step 4: Write the test harness `test/host/harness.h`**

```cpp
#pragma once
#include <cstdio>
#include <cstring>
#include <vector>

struct TestCase {
  const char* name;
  void (*fn)();
};

inline std::vector<TestCase>& testRegistry() {
  static std::vector<TestCase> registry;
  return registry;
}

inline int& testFailures() {
  static int failures = 0;
  return failures;
}

struct TestRegistrar {
  TestRegistrar(const char* name, void (*fn)()) { testRegistry().push_back({name, fn}); }
};

#define TEST(name)                                     \
  static void test_##name();                           \
  static TestRegistrar registrar_##name(#name, test_##name); \
  static void test_##name()

#define EXPECT_TRUE(cond)                                                        \
  do {                                                                           \
    if (!(cond)) {                                                               \
      std::printf("  FAIL %s:%d: expected true: %s\n", __FILE__, __LINE__, #cond); \
      ++testFailures();                                                          \
    }                                                                            \
  } while (0)

#define EXPECT_FALSE(cond) EXPECT_TRUE(!(cond))

#define EXPECT_EQ(a, b)                                                                     \
  do {                                                                                      \
    auto va_ = (a);                                                                         \
    auto vb_ = (b);                                                                         \
    if (!(va_ == vb_)) {                                                                    \
      std::printf("  FAIL %s:%d: %s == %s (%lld vs %lld)\n", __FILE__, __LINE__, #a, #b, \
                  (long long)va_, (long long)vb_);                                          \
      ++testFailures();                                                                     \
    }                                                                                       \
  } while (0)

#define EXPECT_STREQ(a, b)                                                                  \
  do {                                                                                      \
    const char* sa_ = (a);                                                                  \
    const char* sb_ = (b);                                                                  \
    if (std::strcmp(sa_, sb_) != 0) {                                                       \
      std::printf("  FAIL %s:%d: %s == %s (\"%s\" vs \"%s\")\n", __FILE__, __LINE__, #a, #b, \
                  sa_, sb_);                                                                \
      ++testFailures();                                                                     \
    }                                                                                       \
  } while (0)
```

- [ ] **Step 5: Write `test/host/test_main.cpp`**

```cpp
#include "harness.h"

int main() {
  for (const TestCase& test : testRegistry()) {
    const int before = testFailures();
    test.fn();
    std::printf("%s %s\n", before == testFailures() ? "ok  " : "FAIL", test.name);
  }
  std::printf("%zu tests, %d failures\n", testRegistry().size(), testFailures());
  return testFailures() == 0 ? 0 : 1;
}
```

- [ ] **Step 6: Write `tools/run-host-tests.sh`**

```bash
#!/usr/bin/env bash
# Compile src/core with the host tests and run them. No Arduino headers allowed in src/core.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/build/host"
mkdir -p "${OUT}"
clang++ -std=c++17 -Wall -Wextra -Werror -I"${ROOT}/src/core" \
  "${ROOT}"/src/core/*.cpp "${ROOT}"/test/host/*.cpp -o "${OUT}/tests"
"${OUT}/tests"
```

- [ ] **Step 7: Write `tools/build.sh`**

```bash
#!/usr/bin/env bash
# Standalone device build. Cypher OS's tools/build-apps.sh performs the catalog build;
# this script is for local iteration and prints the app binary size.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/build/device"
RETURN_LIB="${CYPHER_OS_RETURN_LIB:-${ROOT}/../cypher-puter-os/libraries/CypherPuterReturn/src}"
EXTRA=""
if [[ -d "${RETURN_LIB}" ]]; then
  EXTRA="-I${RETURN_LIB}"
  echo "[build] using CypherPuterReturn from ${RETURN_LIB}"
else
  echo "[build] CypherPuterReturn not found; standalone restart fallback will be compiled in"
fi
mkdir -p "${OUT}"
arduino-cli compile --profile cardputer-adv --output-dir "${OUT}" \
  --build-property "compiler.cpp.extra_flags=${EXTRA}" "${ROOT}"
BIN="$(find "${OUT}" -maxdepth 1 -name '*.ino.bin' | head -n 1)"
echo "[build] ok $(basename "${BIN}") $(stat -f %z "${BIN}") bytes"
```

- [ ] **Step 8: Write a placeholder sketch so the profile can be verified**

`cypher-airtag.ino`:

```cpp
// Placeholder until Task 10 wires the App. Verifies the profile and libraries resolve.
#include <M5Cardputer.h>
#include <NimBLEDevice.h>

void setup() {
  auto cfg = M5.config();
  M5Cardputer.begin(cfg, true);
}

void loop() {
  M5Cardputer.update();
  delay(20);
}
```

- [ ] **Step 9: Write a README stub**

```markdown
# Cypher AirTag

Passive Apple Find My / AirTag detector for the M5Stack Cardputer ADV, packaged
as a Cypher OS SD catalog app. Full documentation lands with the final task.
```

- [ ] **Step 10: Make scripts executable, run the (empty) host tests and the device build**

The host test script globs `src/core/*.cpp`, which is empty until Task 2, so seed a placeholder that Task 2 deletes:

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && chmod +x tools/*.sh && \
  printf '// removed in Task 2\n' > src/core/placeholder.cpp && tools/run-host-tests.sh
```
Expected: `0 tests, 0 failures`.

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && tools/build.sh
```
Expected: the first run downloads the pinned libraries, ends with `[build] ok cypher-airtag.ino.bin <n> bytes`. If `M5Unified (0.2.14)` / `M5GFX (0.2.20)` fail to resolve with M5Cardputer 1.1.1, change them to `0.2.21` / `0.2.29` in `sketch.yaml` and note the change in the README in Task 13.

- [ ] **Step 11: Commit**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && git add -A && \
git commit -q -m "chore: scaffold Cypher AirTag sketch, host test harness, and build tools

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" && git log --oneline -1
```

---

### Task 2: `findmy_adv` — advertisement parser (TDD)

**Files:**
- Create: `$APP/src/core/findmy_adv.h`, `$APP/src/core/findmy_adv.cpp`
- Test: `$APP/test/host/test_findmy_adv.cpp`
- Delete: `$APP/src/core/placeholder.cpp` if it exists

- [ ] **Step 1: Write the failing tests `test/host/test_findmy_adv.cpp`**

```cpp
#include "findmy_adv.h"
#include "harness.h"

using namespace findmy;

// 4C 00 | 12 19 | status | 22 key bytes | key bits | hint
static const uint8_t kSeparated[] = {
    0x4C, 0x00, 0x12, 0x19,
    0x10,  // status: battery full (00), class AirTag (01)
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B,
    0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16,
    0x40,  // key bits: 01 in the top two bits
    0x00,  // hint
};

// 4C 00 | 12 02 | status | key bits
static const uint8_t kNearby[] = {0x4C, 0x00, 0x12, 0x02, 0x64, 0x80};  // status: medium battery, Find My accessory

TEST(parse_separated_advert) {
  Advert a = parse(kSeparated, sizeof(kSeparated));
  EXPECT_TRUE(a.valid);
  EXPECT_EQ(a.mode, Mode::Separated);
  EXPECT_EQ(a.status, 0x10);
  EXPECT_EQ(a.deviceClass, DeviceClass::AirTag);
  EXPECT_EQ(a.battery, Battery::Full);
  EXPECT_EQ(a.keyBits, 0x40);
  EXPECT_EQ(a.keyTail[0], 0x01);
  EXPECT_EQ(a.keyTail[21], 0x16);
}

TEST(parse_nearby_advert) {
  Advert a = parse(kNearby, sizeof(kNearby));
  EXPECT_TRUE(a.valid);
  EXPECT_EQ(a.mode, Mode::Nearby);
  EXPECT_EQ(a.status, 0x64);
  EXPECT_EQ(a.deviceClass, DeviceClass::FindMyAccessory);
  EXPECT_EQ(a.battery, Battery::Medium);
  EXPECT_EQ(a.keyBits, 0x80);
}

TEST(parse_skips_leading_apple_tlv) {
  // Apple "nearby info" TLV (type 0x10, 5 bytes) chained before the Offline Finding TLV.
  const uint8_t buf[] = {0x4C, 0x00, 0x10, 0x05, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0x12, 0x02, 0x10, 0x00};
  Advert a = parse(buf, sizeof(buf));
  EXPECT_TRUE(a.valid);
  EXPECT_EQ(a.mode, Mode::Nearby);
  EXPECT_EQ(a.status, 0x10);
  EXPECT_EQ(a.keyBits, 0x00);
}

TEST(parse_rejects_wrong_company) {
  const uint8_t buf[] = {0x75, 0x00, 0x12, 0x02, 0x10, 0x00};
  EXPECT_FALSE(parse(buf, sizeof(buf)).valid);
}

TEST(parse_rejects_truncated_tlv) {
  EXPECT_FALSE(parse(kSeparated, sizeof(kSeparated) - 3).valid);
}

TEST(parse_rejects_unknown_offline_finding_length) {
  const uint8_t buf[] = {0x4C, 0x00, 0x12, 0x03, 0x10, 0x00, 0x00};
  EXPECT_FALSE(parse(buf, sizeof(buf)).valid);
}

TEST(parse_rejects_short_and_null_input) {
  EXPECT_FALSE(parse(nullptr, 0).valid);
  const uint8_t buf[] = {0x4C, 0x00, 0x12};
  EXPECT_FALSE(parse(buf, sizeof(buf)).valid);
}

TEST(parse_without_offline_finding_tlv_is_invalid) {
  const uint8_t buf[] = {0x4C, 0x00, 0x10, 0x02, 0x01, 0x02};
  EXPECT_FALSE(parse(buf, sizeof(buf)).valid);
}

TEST(status_decoding_covers_all_values) {
  EXPECT_EQ(deviceClassFromStatus(0x00), DeviceClass::AppleDevice);
  EXPECT_EQ(deviceClassFromStatus(0x10), DeviceClass::AirTag);
  EXPECT_EQ(deviceClassFromStatus(0x20), DeviceClass::FindMyAccessory);
  EXPECT_EQ(deviceClassFromStatus(0x30), DeviceClass::AirPods);
  EXPECT_EQ(batteryFromStatus(0x00), Battery::Full);
  EXPECT_EQ(batteryFromStatus(0x40), Battery::Medium);
  EXPECT_EQ(batteryFromStatus(0x80), Battery::Low);
  EXPECT_EQ(batteryFromStatus(0xC0), Battery::Critical);
  EXPECT_EQ(batteryFromStatus(0xD5), Battery::Critical);       // other bits ignored
  EXPECT_EQ(deviceClassFromStatus(0xD5), DeviceClass::AirTag);  // 1101 0101 -> bits 5-4 = 01
}

TEST(assemble_key_merges_mac_and_tail) {
  const uint8_t mac[6] = {0xFA, 0x11, 0x22, 0x33, 0x44, 0x55};
  uint8_t tail[kKeyTailLen];
  for (size_t i = 0; i < kKeyTailLen; ++i) tail[i] = static_cast<uint8_t>(i + 1);
  uint8_t key[kKeyLen];
  assembleKey(mac, 0x40, tail, key);
  EXPECT_EQ(key[0], 0x7A);  // (0xFA & 0x3F) | 0x40
  EXPECT_EQ(key[1], 0x11);
  EXPECT_EQ(key[5], 0x55);
  EXPECT_EQ(key[6], 0x01);
  EXPECT_EQ(key[27], 0x16);
}

TEST(reconstruct_key_from_separated_advert) {
  const uint8_t mac[6] = {0xFA, 0x11, 0x22, 0x33, 0x44, 0x55};
  Advert a = parse(kSeparated, sizeof(kSeparated));
  uint8_t key[kKeyLen];
  EXPECT_TRUE(reconstructKey(mac, a, key));
  EXPECT_EQ(key[0], 0x7A);
  EXPECT_EQ(key[27], 0x16);
}

TEST(reconstruct_key_fails_for_nearby_and_invalid) {
  const uint8_t mac[6] = {0};
  uint8_t key[kKeyLen];
  EXPECT_FALSE(reconstructKey(mac, parse(kNearby, sizeof(kNearby)), key));
  EXPECT_FALSE(reconstructKey(mac, Advert(), key));
}

TEST(labels_are_stable_strings) {
  EXPECT_STREQ(deviceClassLabel(DeviceClass::AirTag), "airtag");
  EXPECT_STREQ(deviceClassLabel(DeviceClass::FindMyAccessory), "findmy");
  EXPECT_STREQ(deviceClassLabel(DeviceClass::AirPods), "airpods");
  EXPECT_STREQ(deviceClassLabel(DeviceClass::AppleDevice), "apple");
  EXPECT_STREQ(deviceClassShort(DeviceClass::AirTag), "AT");
  EXPECT_STREQ(deviceClassShort(DeviceClass::FindMyAccessory), "FM");
  EXPECT_STREQ(deviceClassShort(DeviceClass::AirPods), "AP");
  EXPECT_STREQ(deviceClassShort(DeviceClass::AppleDevice), "AD");
  EXPECT_STREQ(batteryLabel(Battery::Full), "full");
  EXPECT_STREQ(batteryLabel(Battery::Medium), "medium");
  EXPECT_STREQ(batteryLabel(Battery::Low), "low");
  EXPECT_STREQ(batteryLabel(Battery::Critical), "critical");
  EXPECT_STREQ(modeLabel(Mode::Nearby), "near");
  EXPECT_STREQ(modeLabel(Mode::Separated), "sep");
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && rm -f src/core/placeholder.cpp && tools/run-host-tests.sh
```
Expected: compile error `'findmy_adv.h' file not found`.

- [ ] **Step 3: Write `src/core/findmy_adv.h`**

```cpp
#pragma once
// Apple Offline Finding (Find My) advertisement parser. Pure C++, no Arduino.
#include <stddef.h>
#include <stdint.h>

namespace findmy {

enum class Mode : uint8_t { Nearby, Separated };
enum class DeviceClass : uint8_t { AppleDevice = 0, AirTag = 1, FindMyAccessory = 2, AirPods = 3 };
enum class Battery : uint8_t { Full = 0, Medium = 1, Low = 2, Critical = 3 };

constexpr size_t kKeyTailLen = 22;  // public key bytes 6..27 carried in a separated advert
constexpr size_t kKeyLen = 28;      // full P-224 public key X coordinate

struct Advert {
  bool valid = false;
  Mode mode = Mode::Nearby;
  uint8_t status = 0;
  DeviceClass deviceClass = DeviceClass::AppleDevice;
  Battery battery = Battery::Full;
  uint8_t keyBits = 0;               // top two bits of key byte 0, masked 0xC0
  uint8_t keyTail[kKeyTailLen] = {};  // separated mode only
};

// `data` starts at the little-endian company ID, exactly as NimBLE's getManufacturerData() returns it.
Advert parse(const uint8_t* data, size_t len);

// Full key = MAC with its top two bits replaced by keyBits, followed by the 22-byte tail.
void assembleKey(const uint8_t mac[6], uint8_t keyBits, const uint8_t keyTail[kKeyTailLen], uint8_t out[kKeyLen]);
bool reconstructKey(const uint8_t mac[6], const Advert& adv, uint8_t out[kKeyLen]);

// Status byte heuristics as used by AirGuard. Apple does not document these bits.
DeviceClass deviceClassFromStatus(uint8_t status);  // bits 5-4
Battery batteryFromStatus(uint8_t status);          // bits 7-6

const char* deviceClassLabel(DeviceClass c);  // "airtag" "findmy" "airpods" "apple"
const char* deviceClassShort(DeviceClass c);  // "AT" "FM" "AP" "AD"
const char* batteryLabel(Battery b);          // "full" "medium" "low" "critical"
const char* modeLabel(Mode m);                // "near" "sep"

}  // namespace findmy
```

- [ ] **Step 4: Write `src/core/findmy_adv.cpp`**

```cpp
#include "findmy_adv.h"

#include <string.h>

namespace findmy {
namespace {
constexpr uint8_t kAppleIdLo = 0x4C;
constexpr uint8_t kAppleIdHi = 0x00;
constexpr uint8_t kOfType = 0x12;
constexpr uint8_t kNearbyLen = 0x02;
constexpr uint8_t kSeparatedLen = 0x19;
}  // namespace

DeviceClass deviceClassFromStatus(uint8_t status) {
  return static_cast<DeviceClass>((status >> 4) & 0x03);
}

Battery batteryFromStatus(uint8_t status) {
  return static_cast<Battery>((status >> 6) & 0x03);
}

Advert parse(const uint8_t* data, size_t len) {
  Advert adv;
  if (data == nullptr || len < 4) return adv;
  if (data[0] != kAppleIdLo || data[1] != kAppleIdHi) return adv;

  size_t i = 2;
  while (i + 2 <= len) {
    const uint8_t type = data[i];
    const uint8_t tlen = data[i + 1];
    const uint8_t* payload = data + i + 2;
    if (i + 2 + tlen > len) return adv;  // truncated TLV
    if (type == kOfType) {
      if (tlen == kNearbyLen) {
        adv.mode = Mode::Nearby;
        adv.status = payload[0];
        adv.keyBits = payload[1] & 0xC0;
      } else if (tlen == kSeparatedLen) {
        adv.mode = Mode::Separated;
        adv.status = payload[0];
        memcpy(adv.keyTail, payload + 1, kKeyTailLen);
        adv.keyBits = payload[1 + kKeyTailLen] & 0xC0;
      } else {
        return adv;
      }
      adv.deviceClass = deviceClassFromStatus(adv.status);
      adv.battery = batteryFromStatus(adv.status);
      adv.valid = true;
      return adv;
    }
    i += 2 + tlen;
  }
  return adv;
}

void assembleKey(const uint8_t mac[6], uint8_t keyBits, const uint8_t keyTail[kKeyTailLen], uint8_t out[kKeyLen]) {
  out[0] = static_cast<uint8_t>((mac[0] & 0x3F) | (keyBits & 0xC0));
  memcpy(out + 1, mac + 1, 5);
  memcpy(out + 6, keyTail, kKeyTailLen);
}

bool reconstructKey(const uint8_t mac[6], const Advert& adv, uint8_t out[kKeyLen]) {
  if (!adv.valid || adv.mode != Mode::Separated) return false;
  assembleKey(mac, adv.keyBits, adv.keyTail, out);
  return true;
}

const char* deviceClassLabel(DeviceClass c) {
  switch (c) {
    case DeviceClass::AirTag: return "airtag";
    case DeviceClass::FindMyAccessory: return "findmy";
    case DeviceClass::AirPods: return "airpods";
    case DeviceClass::AppleDevice: break;
  }
  return "apple";
}

const char* deviceClassShort(DeviceClass c) {
  switch (c) {
    case DeviceClass::AirTag: return "AT";
    case DeviceClass::FindMyAccessory: return "FM";
    case DeviceClass::AirPods: return "AP";
    case DeviceClass::AppleDevice: break;
  }
  return "AD";
}

const char* batteryLabel(Battery b) {
  switch (b) {
    case Battery::Medium: return "medium";
    case Battery::Low: return "low";
    case Battery::Critical: return "critical";
    case Battery::Full: break;
  }
  return "full";
}

const char* modeLabel(Mode m) {
  return m == Mode::Separated ? "sep" : "near";
}

}  // namespace findmy
```

- [ ] **Step 5: Run the tests**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && tools/run-host-tests.sh
```
Expected: 13 lines starting `ok  ` and `13 tests, 0 failures`.

- [ ] **Step 6: Commit**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && git add -A && \
git commit -q -m "feat(core): parse Apple Offline Finding adverts

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" && git log --oneline -1
```

---

### Task 3: `format` — string formatters (TDD)

**Files:**
- Create: `$APP/src/core/format.h`, `$APP/src/core/format.cpp`
- Test: `$APP/test/host/test_format.cpp`

- [ ] **Step 1: Write the failing tests `test/host/test_format.cpp`**

```cpp
#include "format.h"

#include <string.h>

#include "harness.h"

using namespace findmy;

TEST(format_mac_is_uppercase_colon_separated) {
  const uint8_t mac[6] = {0xFA, 0x0B, 0x22, 0x33, 0x44, 0x55};
  char out[kMacStrLen];
  formatMac(mac, out);
  EXPECT_STREQ(out, "FA:0B:22:33:44:55");
}

TEST(format_key_hex_is_lowercase_56_chars) {
  uint8_t key[kKeyLen];
  for (size_t i = 0; i < kKeyLen; ++i) key[i] = static_cast<uint8_t>(0xA0 + i);
  char out[kKeyHexLen];
  formatKeyHex(key, out);
  EXPECT_EQ(strlen(out), 56u);
  EXPECT_STREQ(out, "a0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babb");
}

TEST(format_presence_seconds_then_minutes) {
  char out[kPresenceStrLen];
  formatPresence(0, out);
  EXPECT_STREQ(out, "0s");
  formatPresence(59999, out);
  EXPECT_STREQ(out, "59s");
  formatPresence(60000, out);
  EXPECT_STREQ(out, "1m");
  formatPresence(754000, out);
  EXPECT_STREQ(out, "12m");
}

TEST(format_ago_short_and_long) {
  char out[kAgoStrLen];
  formatAgo(2500, out);
  EXPECT_STREQ(out, "2s ago");
  formatAgo(192000, out);
  EXPECT_STREQ(out, "3m12s ago");
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && tools/run-host-tests.sh
```
Expected: compile error `'format.h' file not found`.

- [ ] **Step 3: Write `src/core/format.h`**

```cpp
#pragma once
// Small fixed-buffer string formatters shared by the UI and the event log.
#include <stddef.h>
#include <stdint.h>

#include "findmy_adv.h"

namespace findmy {

constexpr size_t kMacStrLen = 18;       // "AA:BB:CC:DD:EE:FF" + NUL
constexpr size_t kKeyHexLen = 2 * kKeyLen + 1;
constexpr size_t kPresenceStrLen = 8;   // "71582m" + NUL
constexpr size_t kAgoStrLen = 16;       // "71582m59s ago" + NUL

void formatMac(const uint8_t mac[6], char out[kMacStrLen]);
void formatKeyHex(const uint8_t key[kKeyLen], char out[kKeyHexLen]);
void formatPresence(uint32_t ms, char out[kPresenceStrLen]);  // "45s" under a minute, else "12m"
void formatAgo(uint32_t ms, char out[kAgoStrLen]);            // "2s ago" or "3m12s ago"

}  // namespace findmy
```

- [ ] **Step 4: Write `src/core/format.cpp`**

```cpp
#include "format.h"

#include <stdio.h>

namespace findmy {

void formatMac(const uint8_t mac[6], char out[kMacStrLen]) {
  snprintf(out, kMacStrLen, "%02X:%02X:%02X:%02X:%02X:%02X", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
}

void formatKeyHex(const uint8_t key[kKeyLen], char out[kKeyHexLen]) {
  for (size_t i = 0; i < kKeyLen; ++i) {
    snprintf(out + i * 2, 3, "%02x", key[i]);
  }
}

void formatPresence(uint32_t ms, char out[kPresenceStrLen]) {
  const unsigned long seconds = ms / 1000UL;
  if (seconds < 60UL) {
    snprintf(out, kPresenceStrLen, "%lus", seconds);
  } else {
    snprintf(out, kPresenceStrLen, "%lum", seconds / 60UL);
  }
}

void formatAgo(uint32_t ms, char out[kAgoStrLen]) {
  const unsigned long seconds = ms / 1000UL;
  if (seconds < 60UL) {
    snprintf(out, kAgoStrLen, "%lus ago", seconds);
  } else {
    snprintf(out, kAgoStrLen, "%lum%02lus ago", seconds / 60UL, seconds % 60UL);
  }
}

}  // namespace findmy
```

- [ ] **Step 5: Run the tests**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && tools/run-host-tests.sh
```
Expected: `17 tests, 0 failures`.

- [ ] **Step 6: Commit**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && git add -A && \
git commit -q -m "feat(core): add MAC, key, presence, and ago formatters

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" && git log --oneline -1
```

---

### Task 4: `tracker_registry` (TDD)

**Files:**
- Create: `$APP/src/core/tracker_registry.h`, `$APP/src/core/tracker_registry.cpp`
- Test: `$APP/test/host/test_tracker_registry.cpp`

- [ ] **Step 1: Write the failing tests `test/host/test_tracker_registry.cpp`**

```cpp
#include "tracker_registry.h"

#include <string.h>

#include "harness.h"

using namespace findmy;

static Sighting make(uint8_t lastMacByte, int8_t rssi, uint32_t ms, Mode mode) {
  Sighting s{};
  const uint8_t mac[6] = {0xC0, 0x01, 0x02, 0x03, 0x04, lastMacByte};
  memcpy(s.mac, mac, 6);
  s.rssi = rssi;
  s.ms = ms;
  s.adv.valid = true;
  s.adv.mode = mode;
  s.adv.status = 0x10;
  s.adv.deviceClass = DeviceClass::AirTag;
  s.adv.battery = Battery::Full;
  s.adv.keyBits = 0x40;
  for (size_t i = 0; i < kKeyTailLen; ++i) s.adv.keyTail[i] = static_cast<uint8_t>(i);
  return s;
}

TEST(registry_creates_entry_on_first_sighting) {
  TrackerRegistry reg;
  ObserveResult r = reg.observe(make(0x01, -60, 1000, Mode::Separated), 1000);
  EXPECT_TRUE(r.isNew);
  EXPECT_FALSE(r.modeChanged);
  EXPECT_FALSE(r.presenceReset);
  EXPECT_EQ(r.previousMode, Mode::Separated);
  EXPECT_EQ(reg.size(), 1u);
  const Entry* e = reg.at(r.index);
  EXPECT_TRUE(e != nullptr);
  EXPECT_EQ(e->advCount, 1u);
  EXPECT_EQ(e->firstSeenMs, 1000u);
  EXPECT_EQ(e->lastSeenMs, 1000u);
  EXPECT_EQ(e->presenceStartMs, 1000u);
  EXPECT_EQ(e->lastUpdateLogMs, 1000u);
  EXPECT_EQ(e->rssiLast, -60);
  EXPECT_TRUE(e->rssiEma == -60.0f);
  EXPECT_TRUE(e->hasKey);
  EXPECT_EQ(e->keyBits, 0x40);
  EXPECT_EQ(e->keyTail[21], 21);
  EXPECT_FALSE(e->alerted);
  EXPECT_EQ(reg.separatedCount(), 1u);
}

TEST(registry_updates_existing_entry) {
  TrackerRegistry reg;
  reg.observe(make(0x01, -60, 1000, Mode::Nearby), 1000);
  ObserveResult r = reg.observe(make(0x01, -50, 3000, Mode::Separated), 3000);
  EXPECT_FALSE(r.isNew);
  EXPECT_TRUE(r.modeChanged);
  EXPECT_EQ(r.previousMode, Mode::Nearby);
  EXPECT_FALSE(r.presenceReset);
  const Entry* e = reg.at(r.index);
  EXPECT_EQ(e->advCount, 2u);
  EXPECT_EQ(e->lastSeenMs, 3000u);
  EXPECT_EQ(e->presenceStartMs, 1000u);
  EXPECT_EQ(e->mode, Mode::Separated);
  EXPECT_EQ(e->rssiLast, -50);
  EXPECT_TRUE(e->rssiEma > -57.1f && e->rssiEma < -56.9f);  // -60 + 0.3 * 10
  EXPECT_EQ(reg.size(), 1u);
}

TEST(registry_nearby_update_keeps_stored_key) {
  TrackerRegistry reg;
  reg.observe(make(0x01, -60, 1000, Mode::Separated), 1000);
  reg.observe(make(0x01, -60, 2000, Mode::Nearby), 2000);
  const Entry* e = reg.find(make(0x01, 0, 0, Mode::Nearby).mac);
  EXPECT_TRUE(e != nullptr);
  EXPECT_TRUE(e->hasKey);
  EXPECT_EQ(e->mode, Mode::Nearby);
}

TEST(registry_gap_beyond_tolerance_resets_presence) {
  TrackerRegistry reg(120000, 300000);
  reg.observe(make(0x01, -60, 0, Mode::Separated), 0);
  Entry* e = reg.find(make(0x01, 0, 0, Mode::Separated).mac);
  e->alerted = true;
  ObserveResult r = reg.observe(make(0x01, -60, 120001, Mode::Separated), 120001);
  EXPECT_TRUE(r.presenceReset);
  EXPECT_EQ(e->presenceStartMs, 120001u);
  EXPECT_FALSE(e->alerted);
  EXPECT_EQ(e->firstSeenMs, 0u);
}

TEST(registry_gap_within_tolerance_keeps_presence) {
  TrackerRegistry reg(120000, 300000);
  reg.observe(make(0x01, -60, 0, Mode::Separated), 0);
  Entry* e = reg.find(make(0x01, 0, 0, Mode::Separated).mac);
  e->alerted = true;
  ObserveResult r = reg.observe(make(0x01, -60, 120000, Mode::Separated), 120000);
  EXPECT_FALSE(r.presenceReset);
  EXPECT_EQ(e->presenceStartMs, 0u);
  EXPECT_TRUE(e->alerted);
}

TEST(registry_evicts_oldest_when_full) {
  TrackerRegistry reg;
  for (size_t i = 0; i < TrackerRegistry::kCapacity; ++i) {
    const uint32_t t = static_cast<uint32_t>(1000 + i);
    reg.observe(make(static_cast<uint8_t>(i), -60, t, Mode::Nearby), t);
  }
  EXPECT_EQ(reg.size(), TrackerRegistry::kCapacity);
  ObserveResult r = reg.observe(make(0xFF, -60, 9000, Mode::Nearby), 9000);
  EXPECT_TRUE(r.isNew);
  EXPECT_EQ(reg.size(), TrackerRegistry::kCapacity);
  EXPECT_EQ(reg.evictions(), 1u);
  EXPECT_TRUE(reg.find(make(0x00, 0, 0, Mode::Nearby).mac) == nullptr);  // oldest is gone
  EXPECT_TRUE(reg.find(make(0x01, 0, 0, Mode::Nearby).mac) != nullptr);
  EXPECT_TRUE(reg.find(make(0xFF, 0, 0, Mode::Nearby).mac) != nullptr);
}

TEST(registry_expire_removes_and_reports_lost) {
  TrackerRegistry reg(120000, 300000);
  reg.observe(make(0x01, -60, 0, Mode::Separated), 0);
  reg.observe(make(0x02, -60, 200000, Mode::Separated), 200000);
  Entry lost[4];
  const size_t n = reg.expire(300000, lost, 4);
  EXPECT_EQ(n, 1u);
  EXPECT_EQ(lost[0].mac[5], 0x01);
  EXPECT_EQ(reg.size(), 1u);
  EXPECT_TRUE(reg.find(make(0x01, 0, 0, Mode::Nearby).mac) == nullptr);
  EXPECT_TRUE(reg.find(make(0x02, 0, 0, Mode::Nearby).mac) != nullptr);
}

TEST(registry_sorted_by_rssi_descending) {
  TrackerRegistry reg;
  reg.observe(make(0x01, -80, 0, Mode::Nearby), 0);
  reg.observe(make(0x02, -40, 0, Mode::Nearby), 0);
  reg.observe(make(0x03, -60, 0, Mode::Nearby), 0);
  int slots[TrackerRegistry::kCapacity];
  const size_t n = reg.sortedByRssi(slots, TrackerRegistry::kCapacity);
  EXPECT_EQ(n, 3u);
  EXPECT_EQ(reg.at(slots[0])->mac[5], 0x02);
  EXPECT_EQ(reg.at(slots[1])->mac[5], 0x03);
  EXPECT_EQ(reg.at(slots[2])->mac[5], 0x01);
}

TEST(registry_ignores_invalid_advert) {
  TrackerRegistry reg;
  Sighting s = make(0x01, -60, 0, Mode::Nearby);
  s.adv.valid = false;
  ObserveResult r = reg.observe(s, 0);
  EXPECT_EQ(r.index, -1);
  EXPECT_EQ(reg.size(), 0u);
}

TEST(registry_at_out_of_range_and_unused_is_null) {
  TrackerRegistry reg;
  EXPECT_TRUE(reg.at(0) == nullptr);
  EXPECT_TRUE(reg.at(TrackerRegistry::kCapacity) == nullptr);
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && tools/run-host-tests.sh
```
Expected: compile error `'tracker_registry.h' file not found`.

- [ ] **Step 3: Write `src/core/tracker_registry.h`**

```cpp
#pragma once
// Fixed-size table of Find My advertisers keyed by BLE MAC. Pure C++, no Arduino.
#include <stddef.h>
#include <stdint.h>

#include "findmy_adv.h"

namespace findmy {

struct Sighting {
  uint8_t mac[6];  // printed byte order (mac[0] is the first printed byte)
  int8_t rssi;
  uint32_t ms;
  Advert adv;
};

struct Entry {
  bool used = false;
  uint8_t mac[6] = {};
  Mode mode = Mode::Nearby;
  DeviceClass deviceClass = DeviceClass::AppleDevice;
  Battery battery = Battery::Full;
  uint8_t status = 0;
  bool hasKey = false;
  uint8_t keyBits = 0;
  uint8_t keyTail[kKeyTailLen] = {};
  uint32_t firstSeenMs = 0;
  uint32_t lastSeenMs = 0;
  uint32_t presenceStartMs = 0;   // start of the current continuous-presence window
  uint32_t lastUpdateLogMs = 0;   // owned by the caller for periodic "update" log lines
  uint32_t advCount = 0;
  int8_t rssiLast = 0;
  float rssiEma = 0.0f;
  bool alerted = false;           // set by FollowDetector, cleared on presence reset
};

struct ObserveResult {
  int index = -1;
  bool isNew = false;
  bool modeChanged = false;
  bool presenceReset = false;
  Mode previousMode = Mode::Nearby;  // mode before this sighting (equals the new mode for new entries)
};

bool macEquals(const uint8_t a[6], const uint8_t b[6]);

class TrackerRegistry {
 public:
  static constexpr size_t kCapacity = 48;
  static constexpr float kRssiAlpha = 0.3f;

  explicit TrackerRegistry(uint32_t gapToleranceMs = 120000, uint32_t lostAfterMs = 300000);

  // Records a sighting. Invalid adverts are ignored (index == -1).
  ObserveResult observe(const Sighting& s, uint32_t nowMs);
  // Removes entries unseen for lostAfterMs. Copies up to maxOut of them into lostOut
  // and returns the number removed (which may exceed maxOut).
  size_t expire(uint32_t nowMs, Entry* lostOut, size_t maxOut);

  size_t size() const;
  size_t separatedCount() const;
  Entry* at(size_t slot);              // nullptr when out of range or unused
  const Entry* at(size_t slot) const;
  Entry* find(const uint8_t mac[6]);
  const Entry* find(const uint8_t mac[6]) const;
  // Writes the used slots ordered by rssiEma descending. Pass maxOut == kCapacity.
  size_t sortedByRssi(int* slotsOut, size_t maxOut) const;
  uint32_t evictions() const { return evictions_; }
  uint32_t gapToleranceMs() const { return gapToleranceMs_; }
  uint32_t lostAfterMs() const { return lostAfterMs_; }

 private:
  int findSlot(const uint8_t mac[6]) const;
  int allocateSlot();

  Entry entries_[kCapacity];
  uint32_t gapToleranceMs_;
  uint32_t lostAfterMs_;
  uint32_t evictions_ = 0;
};

}  // namespace findmy
```

- [ ] **Step 4: Write `src/core/tracker_registry.cpp`**

```cpp
#include "tracker_registry.h"

#include <string.h>

namespace findmy {

bool macEquals(const uint8_t a[6], const uint8_t b[6]) {
  return memcmp(a, b, 6) == 0;
}

TrackerRegistry::TrackerRegistry(uint32_t gapToleranceMs, uint32_t lostAfterMs)
    : gapToleranceMs_(gapToleranceMs), lostAfterMs_(lostAfterMs) {}

int TrackerRegistry::findSlot(const uint8_t mac[6]) const {
  for (size_t i = 0; i < kCapacity; ++i) {
    if (entries_[i].used && macEquals(entries_[i].mac, mac)) return static_cast<int>(i);
  }
  return -1;
}

int TrackerRegistry::allocateSlot() {
  int oldest = -1;
  for (size_t i = 0; i < kCapacity; ++i) {
    if (!entries_[i].used) return static_cast<int>(i);
    if (oldest < 0 || entries_[i].lastSeenMs < entries_[oldest].lastSeenMs) oldest = static_cast<int>(i);
  }
  ++evictions_;
  return oldest;
}

ObserveResult TrackerRegistry::observe(const Sighting& s, uint32_t nowMs) {
  ObserveResult r;
  if (!s.adv.valid) return r;

  int slot = findSlot(s.mac);
  if (slot < 0) {
    slot = allocateSlot();
    Entry& fresh = entries_[slot];
    fresh = Entry();
    fresh.used = true;
    memcpy(fresh.mac, s.mac, 6);
    fresh.firstSeenMs = nowMs;
    fresh.presenceStartMs = nowMs;
    fresh.lastUpdateLogMs = nowMs;
    fresh.rssiEma = static_cast<float>(s.rssi);
    fresh.mode = s.adv.mode;
    r.isNew = true;
  }

  Entry& e = entries_[slot];
  r.index = slot;
  r.previousMode = e.mode;
  if (!r.isNew) {
    if (nowMs - e.lastSeenMs > gapToleranceMs_) {
      e.presenceStartMs = nowMs;
      e.alerted = false;
      r.presenceReset = true;
    }
    r.modeChanged = e.mode != s.adv.mode;
    e.rssiEma += kRssiAlpha * (static_cast<float>(s.rssi) - e.rssiEma);
  }
  e.lastSeenMs = nowMs;
  e.advCount++;
  e.rssiLast = s.rssi;
  e.mode = s.adv.mode;
  e.deviceClass = s.adv.deviceClass;
  e.battery = s.adv.battery;
  e.status = s.adv.status;
  if (s.adv.mode == Mode::Separated) {
    e.hasKey = true;
    e.keyBits = s.adv.keyBits;
    memcpy(e.keyTail, s.adv.keyTail, kKeyTailLen);
  }
  return r;
}

size_t TrackerRegistry::expire(uint32_t nowMs, Entry* lostOut, size_t maxOut) {
  size_t lost = 0;
  for (size_t i = 0; i < kCapacity; ++i) {
    Entry& e = entries_[i];
    if (!e.used) continue;
    if (nowMs - e.lastSeenMs >= lostAfterMs_) {
      if (lostOut != nullptr && lost < maxOut) lostOut[lost] = e;
      ++lost;
      e.used = false;
    }
  }
  return lost;
}

size_t TrackerRegistry::size() const {
  size_t n = 0;
  for (size_t i = 0; i < kCapacity; ++i) {
    if (entries_[i].used) ++n;
  }
  return n;
}

size_t TrackerRegistry::separatedCount() const {
  size_t n = 0;
  for (size_t i = 0; i < kCapacity; ++i) {
    if (entries_[i].used && entries_[i].mode == Mode::Separated) ++n;
  }
  return n;
}

Entry* TrackerRegistry::at(size_t slot) {
  if (slot >= kCapacity || !entries_[slot].used) return nullptr;
  return &entries_[slot];
}

const Entry* TrackerRegistry::at(size_t slot) const {
  if (slot >= kCapacity || !entries_[slot].used) return nullptr;
  return &entries_[slot];
}

Entry* TrackerRegistry::find(const uint8_t mac[6]) {
  const int slot = findSlot(mac);
  return slot < 0 ? nullptr : &entries_[slot];
}

const Entry* TrackerRegistry::find(const uint8_t mac[6]) const {
  const int slot = findSlot(mac);
  return slot < 0 ? nullptr : &entries_[slot];
}

size_t TrackerRegistry::sortedByRssi(int* slotsOut, size_t maxOut) const {
  size_t n = 0;
  for (size_t i = 0; i < kCapacity && n < maxOut; ++i) {
    if (!entries_[i].used) continue;
    size_t pos = n;
    while (pos > 0 && entries_[slotsOut[pos - 1]].rssiEma < entries_[i].rssiEma) {
      slotsOut[pos] = slotsOut[pos - 1];
      --pos;
    }
    slotsOut[pos] = static_cast<int>(i);
    ++n;
  }
  return n;
}

}  // namespace findmy
```

- [ ] **Step 5: Run the tests**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && tools/run-host-tests.sh
```
Expected: `27 tests, 0 failures`.

- [ ] **Step 6: Commit**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && git add -A && \
git commit -q -m "feat(core): track Find My advertisers in a fixed registry

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" && git log --oneline -1
```

---

### Task 5: `follow_detector` (TDD)

**Files:**
- Create: `$APP/src/core/follow_detector.h`, `$APP/src/core/follow_detector.cpp`
- Test: `$APP/test/host/test_follow_detector.cpp`

- [ ] **Step 1: Write the failing tests `test/host/test_follow_detector.cpp`**

```cpp
#include "follow_detector.h"

#include <string.h>

#include "harness.h"

using namespace findmy;

static Sighting sighting(uint8_t lastMacByte, Mode mode, uint32_t ms, int8_t rssi = -60) {
  Sighting s{};
  const uint8_t mac[6] = {0xD0, 0x01, 0x02, 0x03, 0x04, lastMacByte};
  memcpy(s.mac, mac, 6);
  s.rssi = rssi;
  s.ms = ms;
  s.adv.valid = true;
  s.adv.mode = mode;
  s.adv.status = 0x10;
  s.adv.deviceClass = DeviceClass::AirTag;
  s.adv.battery = Battery::Full;
  return s;
}

// Observe the tag once a minute from fromMs to toMs inclusive, well inside the 2-minute gap tolerance.
static void seen(TrackerRegistry& reg, uint8_t lastMacByte, Mode mode, uint32_t fromMs, uint32_t toMs) {
  for (uint32_t t = fromMs; t <= toMs; t += 60000) reg.observe(sighting(lastMacByte, mode, t), t);
  if ((toMs - fromMs) % 60000 != 0) reg.observe(sighting(lastMacByte, mode, toMs), toMs);
}

static const uint8_t* macOf(uint8_t lastMacByte) {
  static uint8_t mac[6];
  const uint8_t base[6] = {0xD0, 0x01, 0x02, 0x03, 0x04, lastMacByte};
  memcpy(mac, base, 6);
  return mac;
}

TEST(detector_fires_at_threshold_not_before) {
  TrackerRegistry reg;
  FollowDetector det;
  det.setThresholdMs(600000);
  FollowDetector::Alert alerts[4];
  seen(reg, 0x01, Mode::Separated, 0, 599999);
  EXPECT_EQ(det.evaluate(reg, 599999, alerts, 4), 0u);
  seen(reg, 0x01, Mode::Separated, 600000, 600000);
  EXPECT_EQ(det.evaluate(reg, 600000, alerts, 4), 1u);
  EXPECT_EQ(alerts[0].mac[5], 0x01);
  EXPECT_EQ(alerts[0].presenceMs, 600000u);
  EXPECT_EQ(alerts[0].rssi, -60);
  EXPECT_EQ(alerts[0].deviceClass, DeviceClass::AirTag);
  EXPECT_TRUE(reg.find(macOf(0x01))->alerted);
}

TEST(detector_default_threshold_is_ten_minutes) {
  FollowDetector det;
  EXPECT_EQ(det.thresholdMs(), 600000u);
}

TEST(detector_never_fires_for_nearby) {
  TrackerRegistry reg;
  FollowDetector det;
  det.setThresholdMs(600000);
  FollowDetector::Alert alerts[4];
  seen(reg, 0x01, Mode::Nearby, 0, 900000);
  EXPECT_EQ(det.evaluate(reg, 900000, alerts, 4), 0u);
}

TEST(detector_fires_once_per_presence_window) {
  TrackerRegistry reg;
  FollowDetector det;
  det.setThresholdMs(600000);
  FollowDetector::Alert alerts[4];
  seen(reg, 0x01, Mode::Separated, 0, 600000);
  EXPECT_EQ(det.evaluate(reg, 600000, alerts, 4), 1u);
  seen(reg, 0x01, Mode::Separated, 660000, 900000);
  EXPECT_EQ(det.evaluate(reg, 900000, alerts, 4), 0u);
}

TEST(detector_rearms_after_gap) {
  TrackerRegistry reg;
  FollowDetector det;
  det.setThresholdMs(600000);
  FollowDetector::Alert alerts[4];
  seen(reg, 0x01, Mode::Separated, 0, 600000);
  EXPECT_EQ(det.evaluate(reg, 600000, alerts, 4), 1u);
  // 3-minute gap (beyond the 2-minute tolerance), then present for another 10 minutes.
  seen(reg, 0x01, Mode::Separated, 780000, 1380000);
  EXPECT_EQ(det.evaluate(reg, 1380000, alerts, 4), 1u);
  EXPECT_EQ(alerts[0].presenceMs, 600000u);
}

TEST(detector_honours_mute) {
  TrackerRegistry reg;
  FollowDetector det;
  det.setThresholdMs(600000);
  FollowDetector::Alert alerts[4];
  det.mute(macOf(0x01));
  EXPECT_TRUE(det.isMuted(macOf(0x01)));
  EXPECT_FALSE(det.isMuted(macOf(0x02)));
  seen(reg, 0x01, Mode::Separated, 0, 600000);
  EXPECT_EQ(det.evaluate(reg, 600000, alerts, 4), 0u);
  EXPECT_FALSE(reg.find(macOf(0x01))->alerted);
}

TEST(detector_mute_ring_overwrites_oldest) {
  FollowDetector det;
  for (size_t i = 0; i < FollowDetector::kMuteCapacity; ++i) det.mute(macOf(static_cast<uint8_t>(i)));
  EXPECT_TRUE(det.isMuted(macOf(0)));
  det.mute(macOf(0x20));
  EXPECT_FALSE(det.isMuted(macOf(0)));
  EXPECT_TRUE(det.isMuted(macOf(1)));
  EXPECT_TRUE(det.isMuted(macOf(0x20)));
  det.mute(macOf(0x20));  // idempotent: does not consume another slot
  EXPECT_TRUE(det.isMuted(macOf(1)));
}

TEST(detector_threshold_change_applies_on_next_evaluate) {
  TrackerRegistry reg;
  FollowDetector det;
  det.setThresholdMs(600000);
  FollowDetector::Alert alerts[4];
  seen(reg, 0x01, Mode::Separated, 0, 300000);
  EXPECT_EQ(det.evaluate(reg, 300000, alerts, 4), 0u);
  det.setThresholdMs(300000);
  EXPECT_EQ(det.evaluate(reg, 300000, alerts, 4), 1u);
}

TEST(detector_reports_up_to_max_and_marks_only_reported) {
  TrackerRegistry reg;
  FollowDetector det;
  det.setThresholdMs(600000);
  FollowDetector::Alert one[1];
  seen(reg, 0x01, Mode::Separated, 0, 600000);
  seen(reg, 0x02, Mode::Separated, 0, 600000);
  EXPECT_EQ(det.evaluate(reg, 600000, one, 1), 1u);
  EXPECT_EQ(det.evaluate(reg, 600000, one, 1), 1u);
  EXPECT_EQ(det.evaluate(reg, 600000, one, 1), 0u);
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && tools/run-host-tests.sh
```
Expected: compile error `'follow_detector.h' file not found`.

- [ ] **Step 3: Write `src/core/follow_detector.h`**

```cpp
#pragma once
// "Is a separated tag staying with me?" rule over the TrackerRegistry. Pure C++, no Arduino.
#include <stddef.h>
#include <stdint.h>

#include "tracker_registry.h"

namespace findmy {

class FollowDetector {
 public:
  struct Alert {
    uint8_t mac[6];
    uint32_t presenceMs;
    int8_t rssi;
    DeviceClass deviceClass;
  };

  static constexpr size_t kMuteCapacity = 8;
  static constexpr uint32_t kDefaultThresholdMs = 10UL * 60UL * 1000UL;

  void setThresholdMs(uint32_t ms) { thresholdMs_ = ms; }
  uint32_t thresholdMs() const { return thresholdMs_; }

  // Emits at most maxOut alerts for separated, unmuted, not-yet-alerted entries whose
  // continuous presence reached the threshold. Marks only the reported entries as alerted,
  // so any that did not fit are reported on the next call.
  size_t evaluate(TrackerRegistry& reg, uint32_t nowMs, Alert* out, size_t maxOut);

  void mute(const uint8_t mac[6]);  // ring of kMuteCapacity MACs; the oldest is overwritten
  bool isMuted(const uint8_t mac[6]) const;

 private:
  uint32_t thresholdMs_ = kDefaultThresholdMs;
  uint8_t muted_[kMuteCapacity][6] = {};
  bool muteUsed_[kMuteCapacity] = {};
  size_t muteNext_ = 0;
};

}  // namespace findmy
```

- [ ] **Step 4: Write `src/core/follow_detector.cpp`**

```cpp
#include "follow_detector.h"

#include <string.h>

namespace findmy {

size_t FollowDetector::evaluate(TrackerRegistry& reg, uint32_t nowMs, Alert* out, size_t maxOut) {
  if (out == nullptr || maxOut == 0) return 0;
  size_t n = 0;
  for (size_t slot = 0; slot < TrackerRegistry::kCapacity && n < maxOut; ++slot) {
    Entry* e = reg.at(slot);
    if (e == nullptr) continue;
    if (e->mode != Mode::Separated || e->alerted || isMuted(e->mac)) continue;
    const uint32_t presence = nowMs - e->presenceStartMs;
    if (presence < thresholdMs_) continue;
    e->alerted = true;
    memcpy(out[n].mac, e->mac, 6);
    out[n].presenceMs = presence;
    out[n].rssi = e->rssiLast;
    out[n].deviceClass = e->deviceClass;
    ++n;
  }
  return n;
}

void FollowDetector::mute(const uint8_t mac[6]) {
  if (isMuted(mac)) return;
  memcpy(muted_[muteNext_], mac, 6);
  muteUsed_[muteNext_] = true;
  muteNext_ = (muteNext_ + 1) % kMuteCapacity;
}

bool FollowDetector::isMuted(const uint8_t mac[6]) const {
  for (size_t i = 0; i < kMuteCapacity; ++i) {
    if (muteUsed_[i] && macEquals(muted_[i], mac)) return true;
  }
  return false;
}

}  // namespace findmy
```

- [ ] **Step 5: Run the tests**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && tools/run-host-tests.sh
```
Expected: `36 tests, 0 failures`.

- [ ] **Step 6: Commit**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && git add -A && \
git commit -q -m "feat(core): add following-tag alert rule with mute ring

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" && git log --oneline -1
```

---

### Task 6: Device glue without BLE — `version`, `launcher_return`, `settings`, `sound`, `input`

These have no host tests (they touch M5/NVS). The check is that the device build compiles them; they get exercised on hardware in Task 12.

**Files:**
- Create: `$APP/src/device/version.h`, `$APP/src/device/launcher_return.h`, `$APP/src/device/settings.h`, `$APP/src/device/settings.cpp`, `$APP/src/device/sound.h`, `$APP/src/device/sound.cpp`, `$APP/src/device/input.h`, `$APP/src/device/input.cpp`
- Modify: `$APP/cypher-airtag.ino` (temporarily reference the new modules so the compiler sees them)

- [ ] **Step 1: Write `src/device/version.h`**

```cpp
#pragma once
#define CYPHER_AIRTAG_VERSION "0.1.0"
```

- [ ] **Step 2: Write `src/device/launcher_return.h`**

```cpp
#pragma once
// Cypher OS one-shot return when the launcher's header is on the include path
// (tools/build-apps.sh passes -I.../libraries/CypherPuterReturn/src); plain restart otherwise.
#include <Arduino.h>

#if __has_include(<CypherPuterReturn.h>)
#include <CypherPuterReturn.h>
inline bool launcherReturnAvailable() { return true; }
inline void returnToLauncher() { CypherPuter::returnToLauncher(250); }
#else
inline bool launcherReturnAvailable() { return false; }
inline void returnToLauncher() {
  delay(250);
  ESP.restart();
}
#endif
```

- [ ] **Step 3: Write `src/device/settings.h`**

```cpp
#pragma once
// User settings persisted in NVS namespace "cyairtag".
#include <stdint.h>

struct Settings {
  uint8_t thresholdMin = 10;  // one of 5, 10, 15, 30, 60
  bool sound = true;
  bool sdLog = true;
  bool serialJson = true;
  uint32_t boots = 0;  // incremented by load(); used as the log "session" id

  void load();   // reads all fields, bumps and stores the boot counter
  void save();   // writes threshold, sound, sdLog, serialJson
  void cycleThreshold();  // 5 -> 10 -> 15 -> 30 -> 60 -> 5
  uint32_t thresholdMs() const { return static_cast<uint32_t>(thresholdMin) * 60000UL; }
};
```

- [ ] **Step 4: Write `src/device/settings.cpp`**

```cpp
#include "settings.h"

#include <Preferences.h>

namespace {
constexpr const char* kNamespace = "cyairtag";
constexpr uint8_t kChoices[] = {5, 10, 15, 30, 60};
constexpr size_t kChoiceCount = sizeof(kChoices) / sizeof(kChoices[0]);

size_t choiceIndex(uint8_t minutes) {
  for (size_t i = 0; i < kChoiceCount; ++i) {
    if (kChoices[i] == minutes) return i;
  }
  return 1;  // 10 minutes
}
}  // namespace

void Settings::load() {
  Preferences prefs;
  if (!prefs.begin(kNamespace, false)) return;
  thresholdMin = kChoices[choiceIndex(prefs.getUChar("thresh", 10))];
  sound = prefs.getBool("sound", true);
  sdLog = prefs.getBool("sdlog", true);
  serialJson = prefs.getBool("serial", true);
  boots = prefs.getUInt("boots", 0) + 1;
  prefs.putUInt("boots", boots);
  prefs.end();
}

void Settings::save() {
  Preferences prefs;
  if (!prefs.begin(kNamespace, false)) return;
  prefs.putUChar("thresh", thresholdMin);
  prefs.putBool("sound", sound);
  prefs.putBool("sdlog", sdLog);
  prefs.putBool("serial", serialJson);
  prefs.end();
}

void Settings::cycleThreshold() {
  thresholdMin = kChoices[(choiceIndex(thresholdMin) + 1) % kChoiceCount];
}
```

- [ ] **Step 5: Write `src/device/sound.h`**

```cpp
#pragma once
// Non-blocking alert chirps and RSSI-paced locate beeps on the Cardputer speaker.
#include <stdint.h>

class Sound {
 public:
  void begin();
  void setEnabled(bool on) { enabled_ = on; }
  bool enabled() const { return enabled_; }

  void alertChirps();  // three 1200 Hz / 80 ms chirps, 120 ms apart, played by tick()
  void startLocate();
  void stopLocate();
  bool locateActive() const { return locate_; }
  // fresh == false (tag unseen for 5 s) holds the slowest cadence.
  void setLocateRssi(float rssiEma, bool fresh);
  void tick(uint32_t nowMs);

 private:
  bool enabled_ = true;
  uint8_t chirpsLeft_ = 0;
  uint32_t nextChirpMs_ = 0;
  bool locate_ = false;
  uint32_t nextBeepMs_ = 0;
  uint32_t periodMs_ = 1500;
};
```

- [ ] **Step 6: Write `src/device/sound.cpp`**

```cpp
#include "sound.h"

#include <M5Cardputer.h>

namespace {
constexpr float kChirpHz = 1200.0f;
constexpr uint32_t kChirpMs = 80;
constexpr uint32_t kChirpGapMs = 120;
constexpr float kBeepHz = 880.0f;
constexpr uint32_t kBeepMs = 30;
constexpr uint32_t kSlowestPeriodMs = 1500;
constexpr uint32_t kFastestPeriodMs = 150;
constexpr float kFarDbm = -90.0f;
constexpr float kNearDbm = -40.0f;
}  // namespace

void Sound::begin() {
  M5Cardputer.Speaker.begin();
  M5Cardputer.Speaker.setVolume(160);
}

void Sound::alertChirps() {
  chirpsLeft_ = 3;
  nextChirpMs_ = 0;
}

void Sound::startLocate() {
  locate_ = true;
  nextBeepMs_ = 0;
}

void Sound::stopLocate() {
  locate_ = false;
}

void Sound::setLocateRssi(float rssiEma, bool fresh) {
  if (!fresh) {
    periodMs_ = kSlowestPeriodMs;
    return;
  }
  float dbm = rssiEma;
  if (dbm < kFarDbm) dbm = kFarDbm;
  if (dbm > kNearDbm) dbm = kNearDbm;
  const float span = kNearDbm - kFarDbm;                       // 50 dB
  const float t = (dbm - kFarDbm) / span;                      // 0 far .. 1 near
  periodMs_ = kSlowestPeriodMs - static_cast<uint32_t>(t * (kSlowestPeriodMs - kFastestPeriodMs));
}

void Sound::tick(uint32_t nowMs) {
  if (!enabled_) {
    chirpsLeft_ = 0;
    return;
  }
  if (chirpsLeft_ > 0 && nowMs >= nextChirpMs_) {
    M5Cardputer.Speaker.tone(kChirpHz, kChirpMs);
    nextChirpMs_ = nowMs + kChirpMs + kChirpGapMs;
    --chirpsLeft_;
  }
  if (locate_ && nowMs >= nextBeepMs_) {
    M5Cardputer.Speaker.tone(kBeepHz, kBeepMs);
    nextBeepMs_ = nowMs + periodMs_;
  }
}
```

- [ ] **Step 7: Write `src/device/input.h`**

```cpp
#pragma once
// Keyboard + BtnA sampling with the same key map as the Cypher OS launcher.

struct InputEvent {
  bool up = false;      // ; , w k
  bool down = false;    // . / s j
  bool left = false;    // a h
  bool right = false;   // d l
  bool select = false;  // Enter, BtnA
  bool back = false;    // Del, Tab, `, q
  bool mute = false;    // m
  bool space = false;   // Space
  bool any = false;
};

InputEvent readInput();
```

- [ ] **Step 8: Write `src/device/input.cpp`**

```cpp
#include "input.h"

#include <M5Cardputer.h>

InputEvent readInput() {
  InputEvent ev;
  ev.select = M5Cardputer.BtnA.wasClicked();

  if (M5Cardputer.Keyboard.isChange() && M5Cardputer.Keyboard.isPressed()) {
    Keyboard_Class::KeysState keys = M5Cardputer.Keyboard.keysState();
    ev.select = ev.select || keys.enter;
    ev.back = keys.del || keys.tab;
    ev.space = keys.space;
    for (auto c : keys.word) {
      switch (c) {
        case ';': case ',': case 'w': case 'W': case 'k': case 'K': ev.up = true; break;
        case '.': case '/': case 's': case 'S': case 'j': case 'J': ev.down = true; break;
        case 'a': case 'A': case 'h': case 'H': ev.left = true; break;
        case 'd': case 'D': case 'l': case 'L': ev.right = true; break;
        case '`': case 'q': case 'Q': ev.back = true; break;
        case 'm': case 'M': ev.mute = true; break;
        case ' ': ev.space = true; break;
        default: break;
      }
    }
  }

  ev.any = ev.up || ev.down || ev.left || ev.right || ev.select || ev.back || ev.mute || ev.space;
  return ev;
}
```

- [ ] **Step 9: Reference the modules from the placeholder sketch so they compile**

Replace `cypher-airtag.ino` with:

```cpp
// Placeholder until Task 10 wires the App. Pulls in the device modules so they compile.
#include <M5Cardputer.h>

#include "src/device/input.h"
#include "src/device/launcher_return.h"
#include "src/device/settings.h"
#include "src/device/sound.h"
#include "src/device/version.h"

static Settings settings;
static Sound sound;

void setup() {
  auto cfg = M5.config();
  M5Cardputer.begin(cfg, true);
  settings.load();
  sound.begin();
  sound.setEnabled(settings.sound);
}

void loop() {
  M5Cardputer.update();
  InputEvent ev = readInput();
  if (ev.back) returnToLauncher();
  sound.tick(millis());
  delay(20);
}
```

- [ ] **Step 10: Build for the device**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && tools/build.sh
```
Expected: `[build] using CypherPuterReturn from ...` then `[build] ok cypher-airtag.ino.bin <n> bytes`. If `keys.space` does not exist in the installed M5Cardputer, delete the line `ev.space = keys.space;` (the `' '` case in the switch still covers it).

- [ ] **Step 11: Commit**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && git add -A && \
git commit -q -m "feat(device): add settings, sound, input, and launcher return glue

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" && git log --oneline -1
```

---

### Task 7: `ble_scanner` — NimBLE passive scan into a FreeRTOS queue

**Files:**
- Create: `$APP/src/device/ble_scanner.h`, `$APP/src/device/ble_scanner.cpp`
- Modify: `$APP/cypher-airtag.ino` (placeholder references the scanner so it compiles)

- [ ] **Step 1: Write `src/device/ble_scanner.h`**

```cpp
#pragma once
// NimBLE passive scan. The NimBLE host task parses every advert and queues valid Find My
// sightings; the Arduino loop drains them with poll(). Nothing else runs on the BLE task.
#include <stdint.h>

#include "../core/tracker_registry.h"

class BleScanner {
 public:
  bool begin();                          // false on failure; see lastError()
  bool poll(findmy::Sighting& out);      // one queued sighting, or false when empty
  uint32_t received() const;             // valid Find My adverts queued
  uint32_t dropped() const;              // adverts lost because the queue was full
  const char* lastError() const;
};
```

- [ ] **Step 2: Write `src/device/ble_scanner.cpp`**

```cpp
#include "ble_scanner.h"

#include <Arduino.h>
#include <NimBLEDevice.h>
#include <freertos/FreeRTOS.h>
#include <freertos/queue.h>

#include "../core/findmy_adv.h"

namespace {
constexpr size_t kQueueDepth = 32;
constexpr uint16_t kScanIntervalMs = 100;
constexpr uint16_t kScanWindowMs = 100;  // window == interval: 100% duty passive scan

QueueHandle_t gQueue = nullptr;
volatile uint32_t gReceived = 0;
volatile uint32_t gDropped = 0;
const char* gLastError = "";

class ScanCallbacks : public NimBLEScanCallbacks {
  void onResult(const NimBLEAdvertisedDevice* dev) override {
    if (!dev->haveManufacturerData()) return;
    const std::string mfg = dev->getManufacturerData();
    const findmy::Advert adv = findmy::parse(reinterpret_cast<const uint8_t*>(mfg.data()), mfg.size());
    if (!adv.valid) return;

    findmy::Sighting s{};
    const NimBLEAddress addr = dev->getAddress();  // keep the copy alive while reading getVal()
    const uint8_t* raw = addr.getVal();            // little-endian
    for (int i = 0; i < 6; ++i) s.mac[i] = raw[5 - i];
    s.rssi = static_cast<int8_t>(dev->getRSSI());
    s.ms = millis();
    s.adv = adv;
    if (gQueue != nullptr && xQueueSend(gQueue, &s, 0) == pdTRUE) {
      gReceived = gReceived + 1;
    } else {
      gDropped = gDropped + 1;
    }
  }

  void onScanEnd(const NimBLEScanResults&, int) override {
    NimBLEDevice::getScan()->start(0, false, true);
  }
};

ScanCallbacks gCallbacks;
}  // namespace

bool BleScanner::begin() {
  if (gQueue == nullptr) gQueue = xQueueCreate(kQueueDepth, sizeof(findmy::Sighting));
  if (gQueue == nullptr) {
    gLastError = "queue alloc failed";
    return false;
  }
  if (!NimBLEDevice::init("")) {
    gLastError = "NimBLE init failed";
    return false;
  }
  NimBLEScan* scan = NimBLEDevice::getScan();
  scan->setScanCallbacks(&gCallbacks, true);  // true: report duplicates so RSSI keeps updating
  scan->setActiveScan(false);
  scan->setInterval(kScanIntervalMs);
  scan->setWindow(kScanWindowMs);
  scan->setDuplicateFilter(false);
  scan->setMaxResults(0);  // do not buffer results; callbacks are the only consumer
  if (!scan->start(0, false, true)) {
    gLastError = "scan start failed";
    return false;
  }
  return true;
}

bool BleScanner::poll(findmy::Sighting& out) {
  return gQueue != nullptr && xQueueReceive(gQueue, &out, 0) == pdTRUE;
}

uint32_t BleScanner::received() const { return gReceived; }
uint32_t BleScanner::dropped() const { return gDropped; }
const char* BleScanner::lastError() const { return gLastError; }
```

- [ ] **Step 3: Reference the scanner from the placeholder sketch**

Replace `cypher-airtag.ino` with:

```cpp
// Placeholder until Task 10 wires the App. Streams parsed Find My sightings over serial.
#include <M5Cardputer.h>

#include "src/core/format.h"
#include "src/device/ble_scanner.h"
#include "src/device/input.h"
#include "src/device/launcher_return.h"
#include "src/device/settings.h"
#include "src/device/sound.h"
#include "src/device/version.h"

static Settings settings;
static Sound sound;
static BleScanner scanner;

void setup() {
  Serial.begin(115200);
  Serial.setTxTimeoutMs(0);
  auto cfg = M5.config();
  M5Cardputer.begin(cfg, true);
  settings.load();
  sound.begin();
  sound.setEnabled(settings.sound);
  if (!scanner.begin()) Serial.println(scanner.lastError());
}

void loop() {
  M5Cardputer.update();
  findmy::Sighting s;
  while (scanner.poll(s)) {
    char mac[findmy::kMacStrLen];
    findmy::formatMac(s.mac, mac);
    Serial.printf("%s %s %s %d\n", mac, findmy::deviceClassShort(s.adv.deviceClass), findmy::modeLabel(s.adv.mode), s.rssi);
  }
  InputEvent ev = readInput();
  if (ev.back) returnToLauncher();
  sound.tick(millis());
  delay(20);
}
```

- [ ] **Step 4: Build for the device**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && tools/build.sh
```
Expected: `[build] ok cypher-airtag.ino.bin <n> bytes` (expect roughly 1.0–1.3 MB now that NimBLE is linked).

- [ ] **Step 5: Commit**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && git add -A && \
git commit -q -m "feat(device): passive NimBLE scan feeding a sighting queue

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" && git log --oneline -1
```

---

### Task 8: `event_log` — JSONL to SD and serial

**Files:**
- Create: `$APP/src/device/event_log.h`, `$APP/src/device/event_log.cpp`
- Modify: `$APP/cypher-airtag.ino` (placeholder references the log so it compiles)

- [ ] **Step 1: Write `src/device/event_log.h`**

```cpp
#pragma once
// JSON-lines event log: each event goes to /cypher-airtag/logs/findmy.jsonl on SD and to USB serial.
#include <stdint.h>

#include "../core/follow_detector.h"
#include "../core/tracker_registry.h"

class EventLog {
 public:
  enum class SdState : uint8_t { Off, Mounted, Missing, WriteError };

  void begin(uint32_t session, bool sdEnabled, bool serialEnabled);
  void setSdEnabled(bool on);  // turning it on (re)mounts the card, which retries after errors
  void setSerialEnabled(bool on) { serial_ = on; }
  SdState sdState() const { return sdState_; }
  const char* sdStateLabel() const;  // "off" "mounted" "missing" "write_error"
  bool sdUsable() const { return sd_ && sdState_ == SdState::Mounted; }
  bool sdWarning() const { return sd_ && sdState_ != SdState::Mounted; }

  void logBoot(const char* firmware, uint8_t thresholdMin, uint32_t nowMs);
  void logSeen(const findmy::Entry& e, uint32_t nowMs);
  void logUpdate(const findmy::Entry& e, uint32_t nowMs);
  void logMode(const findmy::Entry& e, findmy::Mode from, uint32_t nowMs);
  void logAlert(const findmy::FollowDetector::Alert& a, uint32_t nowMs);
  void logMute(const uint8_t mac[6], uint32_t nowMs);
  void logLost(const findmy::Entry& e, uint32_t nowMs);
  void logSd(uint32_t nowMs);

 private:
  bool mountSd();
  void emit(const char* line);
  void appendSd(const char* line);

  uint32_t session_ = 0;
  bool sd_ = false;
  bool serial_ = true;
  SdState sdState_ = SdState::Off;
};
```

- [ ] **Step 2: Write `src/device/event_log.cpp`**

```cpp
#include "event_log.h"

#include <Arduino.h>
#include <SD.h>
#include <SPI.h>
#include <stdio.h>

#include "../core/format.h"

namespace {
// Same SD wiring the Cypher OS launcher uses.
constexpr uint8_t kSdCs = 12;
constexpr uint8_t kSdSck = 40;
constexpr uint8_t kSdMiso = 39;
constexpr uint8_t kSdMosi = 14;
constexpr uint32_t kSdHz = 25000000;
constexpr const char* kDir = "/cypher-airtag";
constexpr const char* kLogDir = "/cypher-airtag/logs";
constexpr const char* kLogPath = "/cypher-airtag/logs/findmy.jsonl";
constexpr const char* kRotatedPath = "/cypher-airtag/logs/findmy.1.jsonl";
constexpr size_t kRotateBytes = 4UL * 1024UL * 1024UL;
constexpr size_t kLineLen = 320;

SPIClass gSdSpi(FSPI);

unsigned long seconds(uint32_t ms) { return static_cast<unsigned long>(ms / 1000UL); }
}  // namespace

void EventLog::begin(uint32_t session, bool sdEnabled, bool serialEnabled) {
  session_ = session;
  serial_ = serialEnabled;
  sd_ = sdEnabled;
  sdState_ = SdState::Off;
  if (sd_) mountSd();
}

void EventLog::setSdEnabled(bool on) {
  sd_ = on;
  if (on) {
    SD.end();
    mountSd();
  } else {
    sdState_ = SdState::Off;
  }
}

bool EventLog::mountSd() {
  gSdSpi.end();
  gSdSpi.begin(kSdSck, kSdMiso, kSdMosi, kSdCs);
  if (!SD.begin(kSdCs, gSdSpi, kSdHz)) {
    sdState_ = SdState::Missing;
    return false;
  }
  if (!SD.exists(kDir)) SD.mkdir(kDir);
  if (!SD.exists(kLogDir)) SD.mkdir(kLogDir);
  sdState_ = SdState::Mounted;
  return true;
}

const char* EventLog::sdStateLabel() const {
  switch (sdState_) {
    case SdState::Mounted: return "mounted";
    case SdState::Missing: return "missing";
    case SdState::WriteError: return "write_error";
    case SdState::Off: break;
  }
  return "off";
}

void EventLog::emit(const char* line) {
  if (serial_) Serial.println(line);
  if (sdUsable()) appendSd(line);
}

void EventLog::appendSd(const char* line) {
  File file = SD.open(kLogPath, FILE_APPEND);
  if (!file) {
    sdState_ = SdState::WriteError;
    return;
  }
  if (file.size() > kRotateBytes) {
    file.close();
    SD.remove(kRotatedPath);
    SD.rename(kLogPath, kRotatedPath);
    file = SD.open(kLogPath, FILE_APPEND);
    if (!file) {
      sdState_ = SdState::WriteError;
      return;
    }
  }
  const size_t written = file.println(line);
  file.close();
  if (written == 0) sdState_ = SdState::WriteError;
}

void EventLog::logBoot(const char* firmware, uint8_t thresholdMin, uint32_t nowMs) {
  char line[kLineLen];
  snprintf(line, sizeof(line),
           "{\"ev\":\"boot\",\"t\":%lu,\"session\":%lu,\"fw\":\"%s\",\"sd\":\"%s\",\"thresh_min\":%u}",
           (unsigned long)nowMs, (unsigned long)session_, firmware, sdStateLabel(), (unsigned)thresholdMin);
  emit(line);
}

void EventLog::logSeen(const findmy::Entry& e, uint32_t nowMs) {
  char mac[findmy::kMacStrLen];
  findmy::formatMac(e.mac, mac);
  char keyHex[findmy::kKeyHexLen] = "";
  if (e.hasKey && e.mode == findmy::Mode::Separated) {
    uint8_t key[findmy::kKeyLen];
    findmy::assembleKey(e.mac, e.keyBits, e.keyTail, key);
    findmy::formatKeyHex(key, keyHex);
  }
  char line[kLineLen];
  snprintf(line, sizeof(line),
           "{\"ev\":\"seen\",\"t\":%lu,\"session\":%lu,\"mac\":\"%s\",\"cls\":\"%s\",\"mode\":\"%s\","
           "\"rssi\":%d,\"batt\":\"%s\",\"status\":\"0x%02X\",\"key\":\"%s\"}",
           (unsigned long)nowMs, (unsigned long)session_, mac, findmy::deviceClassLabel(e.deviceClass),
           findmy::modeLabel(e.mode), (int)e.rssiLast, findmy::batteryLabel(e.battery), (unsigned)e.status, keyHex);
  emit(line);
}

void EventLog::logUpdate(const findmy::Entry& e, uint32_t nowMs) {
  char mac[findmy::kMacStrLen];
  findmy::formatMac(e.mac, mac);
  char line[kLineLen];
  snprintf(line, sizeof(line),
           "{\"ev\":\"update\",\"t\":%lu,\"session\":%lu,\"mac\":\"%s\",\"mode\":\"%s\",\"rssi_ema\":%.1f,"
           "\"advs\":%lu,\"presence_s\":%lu}",
           (unsigned long)nowMs, (unsigned long)session_, mac, findmy::modeLabel(e.mode), (double)e.rssiEma,
           (unsigned long)e.advCount, seconds(nowMs - e.presenceStartMs));
  emit(line);
}

void EventLog::logMode(const findmy::Entry& e, findmy::Mode from, uint32_t nowMs) {
  char mac[findmy::kMacStrLen];
  findmy::formatMac(e.mac, mac);
  char line[kLineLen];
  snprintf(line, sizeof(line), "{\"ev\":\"mode\",\"t\":%lu,\"session\":%lu,\"mac\":\"%s\",\"from\":\"%s\",\"to\":\"%s\"}",
           (unsigned long)nowMs, (unsigned long)session_, mac, findmy::modeLabel(from), findmy::modeLabel(e.mode));
  emit(line);
}

void EventLog::logAlert(const findmy::FollowDetector::Alert& a, uint32_t nowMs) {
  char mac[findmy::kMacStrLen];
  findmy::formatMac(a.mac, mac);
  char line[kLineLen];
  snprintf(line, sizeof(line),
           "{\"ev\":\"alert\",\"t\":%lu,\"session\":%lu,\"mac\":\"%s\",\"cls\":\"%s\",\"presence_s\":%lu,\"rssi\":%d}",
           (unsigned long)nowMs, (unsigned long)session_, mac, findmy::deviceClassLabel(a.deviceClass),
           seconds(a.presenceMs), (int)a.rssi);
  emit(line);
}

void EventLog::logMute(const uint8_t macBytes[6], uint32_t nowMs) {
  char mac[findmy::kMacStrLen];
  findmy::formatMac(macBytes, mac);
  char line[kLineLen];
  snprintf(line, sizeof(line), "{\"ev\":\"mute\",\"t\":%lu,\"session\":%lu,\"mac\":\"%s\"}",
           (unsigned long)nowMs, (unsigned long)session_, mac);
  emit(line);
}

void EventLog::logLost(const findmy::Entry& e, uint32_t nowMs) {
  char mac[findmy::kMacStrLen];
  findmy::formatMac(e.mac, mac);
  char line[kLineLen];
  snprintf(line, sizeof(line),
           "{\"ev\":\"lost\",\"t\":%lu,\"session\":%lu,\"mac\":\"%s\",\"presence_s\":%lu,\"advs\":%lu}",
           (unsigned long)nowMs, (unsigned long)session_, mac, seconds(e.lastSeenMs - e.presenceStartMs),
           (unsigned long)e.advCount);
  emit(line);
}

void EventLog::logSd(uint32_t nowMs) {
  char line[kLineLen];
  snprintf(line, sizeof(line), "{\"ev\":\"sd\",\"t\":%lu,\"session\":%lu,\"state\":\"%s\"}",
           (unsigned long)nowMs, (unsigned long)session_, sdStateLabel());
  emit(line);
}
```

- [ ] **Step 3: Reference the log from the placeholder sketch**

In `cypher-airtag.ino` add `#include "src/device/event_log.h"` after the `ble_scanner.h` include, add `static EventLog eventLog;` after `static BleScanner scanner;`, and add these two lines at the end of `setup()`:

```cpp
  eventLog.begin(settings.boots, settings.sdLog, settings.serialJson);
  eventLog.logBoot(CYPHER_AIRTAG_VERSION, settings.thresholdMin, millis());
```

- [ ] **Step 4: Build for the device**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && tools/build.sh
```
Expected: `[build] ok ...`.

- [ ] **Step 5: Commit**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && git add -A && \
git commit -q -m "feat(device): JSONL event log to SD and USB serial

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" && git log --oneline -1
```

---

### Task 9: `ui` — pages, overlay, confirm dialog

**Files:**
- Create: `$APP/src/device/ui.h`, `$APP/src/device/ui.cpp`

- [ ] **Step 1: Write `src/device/ui.h`**

```cpp
#pragma once
// Renders every page, the alert overlay, and the return confirm dialog. Render-only: no input logic.
#include <stddef.h>
#include <stdint.h>

#include <M5Cardputer.h>

#include "../core/tracker_registry.h"
#include "settings.h"

enum class Page : uint8_t { Radar, Alerts, Settings, Detail, About };

struct AlertRecord {
  uint8_t mac[6];
  uint32_t atMs;
  uint32_t presenceMs;
  int8_t rssi;
  findmy::DeviceClass deviceClass;
};

struct UiState {
  Page page = Page::Radar;
  Page returnPage = Page::Radar;  // where Detail's back goes
  int radarSel = 0;
  int alertSel = 0;
  int settingsSel = 0;
  uint8_t detailMac[6] = {};
  bool detailValid = false;
  bool confirmReturn = false;
  bool overlay = false;
  AlertRecord overlayAlert{};
  bool locate = false;
  bool bleError = false;
  char bleErrorText[48] = "";
  bool sdWarning = false;
  const char* sdLabel = "off";
  uint32_t queueReceived = 0;
  uint32_t queueDropped = 0;
  uint32_t evictions = 0;
  uint32_t session = 0;
  bool launcherReturn = false;
};

constexpr int kSettingsRowCount = 6;  // threshold, sound, SD log, serial JSON, return, about

class Ui {
 public:
  static constexpr int kRows = 6;

  void begin();
  void draw(const UiState& st, const findmy::TrackerRegistry& reg, const Settings& settings,
            const AlertRecord* alerts, size_t alertCount, uint32_t nowMs);
  void drawMessage(const char* title, const char* body);

 private:
  LovyanGFX& g();
  void present();
  void text(int x, int y, const char* s, uint16_t fg, uint16_t bg);
  void drawHeader(const UiState& st, const findmy::TrackerRegistry& reg);
  void drawFooter(const char* hints);
  void drawFooterStatus(const UiState& st);
  void drawRadar(const UiState& st, const findmy::TrackerRegistry& reg, uint32_t nowMs);
  void drawBleError(const UiState& st);
  void drawAlerts(const UiState& st, const findmy::TrackerRegistry& reg, const Settings& settings,
                  const AlertRecord* alerts, size_t alertCount, uint32_t nowMs);
  void drawSettings(const UiState& st, const Settings& settings);
  void drawDetail(const UiState& st, const findmy::TrackerRegistry& reg, uint32_t nowMs);
  void drawAbout(const UiState& st, uint32_t nowMs);
  void drawOverlay(const UiState& st);
  void drawConfirm();
  void drawRssiCells(int x, int y, float rssiEma, uint16_t color);

  M5Canvas canvas_;
  bool buffered_ = false;
  uint8_t spinner_ = 0;
};
```

- [ ] **Step 2: Write `src/device/ui.cpp`**

```cpp
#include "ui.h"

#include <math.h>
#include <stdio.h>
#include <string.h>

#include "../core/findmy_adv.h"
#include "../core/format.h"
#include "version.h"

namespace {
// Cypher OS launcher "Neon Grid" palette.
constexpr uint16_t COLOR_BG = 0x0000;
constexpr uint16_t COLOR_PANEL = 0x0841;
constexpr uint16_t COLOR_TEXT = 0xFFFF;
constexpr uint16_t COLOR_DIM = 0x9CD3;
constexpr uint16_t COLOR_ACCENT = 0x07FF;
constexpr uint16_t COLOR_WARN = 0xFD20;
constexpr uint16_t COLOR_BAD = 0xF800;
constexpr uint16_t COLOR_GOOD = 0x07E0;
constexpr uint16_t COLOR_HEADER = 0x0186;
constexpr uint16_t COLOR_FOOTER = 0x1082;
constexpr uint16_t COLOR_SELECTED = 0x034F;
constexpr uint16_t COLOR_SELECTED_TEXT = 0x0000;

constexpr int kW = 240;
constexpr int kH = 135;
constexpr int kHeaderH = 20;
constexpr int kFooterH = 14;
constexpr int kRowY0 = 22;
constexpr int kRowH = 16;
constexpr int kCharW = 6;  // built-in 6x8 font at text size 1
constexpr char kSpinner[] = "|/-\\";

const char* pageName(Page p) {
  switch (p) {
    case Page::Radar: return "RADAR";
    case Page::Alerts: return "ALERTS";
    case Page::Settings: return "SETTINGS";
    case Page::Detail: return "DETAIL";
    case Page::About: return "ABOUT";
  }
  return "";
}

int rssiCells(float rssiEma) {
  int cells = static_cast<int>(lroundf((rssiEma + 95.0f) / 10.0f));
  if (cells < 0) cells = 0;
  if (cells > 5) cells = 5;
  return cells;
}

int clampSel(int sel, int count) {
  if (count <= 0 || sel < 0) return 0;
  return sel >= count ? count - 1 : sel;
}

int firstVisible(int sel, int rows) {
  const int first = sel - rows + 1;
  return first < 0 ? 0 : first;
}

void shortId(const uint8_t mac[6], char out[5]) {
  snprintf(out, 5, "%02X%02X", mac[4], mac[5]);
}
}  // namespace

void Ui::begin() {
  canvas_.setColorDepth(16);
  buffered_ = canvas_.createSprite(kW, kH) != nullptr;
  LovyanGFX& d = g();
  d.setTextSize(1);
  d.setTextWrap(false);
  d.setTextDatum(top_left);
}

LovyanGFX& Ui::g() {
  if (buffered_) return canvas_;
  return M5Cardputer.Display;
}

void Ui::present() {
  if (buffered_) canvas_.pushSprite(&M5Cardputer.Display, 0, 0);
}

void Ui::text(int x, int y, const char* s, uint16_t fg, uint16_t bg) {
  LovyanGFX& d = g();
  d.setTextColor(fg, bg);
  d.setCursor(x, y);
  d.print(s);
}

void Ui::draw(const UiState& st, const findmy::TrackerRegistry& reg, const Settings& settings,
              const AlertRecord* alerts, size_t alertCount, uint32_t nowMs) {
  g().fillScreen(COLOR_BG);
  drawHeader(st, reg);
  switch (st.page) {
    case Page::Radar:
      if (st.bleError) drawBleError(st);
      else drawRadar(st, reg, nowMs);
      break;
    case Page::Alerts: drawAlerts(st, reg, settings, alerts, alertCount, nowMs); break;
    case Page::Settings: drawSettings(st, settings); break;
    case Page::Detail: drawDetail(st, reg, nowMs); break;
    case Page::About: drawAbout(st, nowMs); break;
  }
  drawFooterStatus(st);
  if (st.confirmReturn) drawConfirm();
  if (st.overlay) drawOverlay(st);
  present();
}

void Ui::drawMessage(const char* title, const char* body) {
  LovyanGFX& d = g();
  d.fillScreen(COLOR_BG);
  d.fillRect(0, 0, kW, kHeaderH, COLOR_HEADER);
  text(6, 6, title, COLOR_TEXT, COLOR_HEADER);
  text(8, 48, body, COLOR_ACCENT, COLOR_BG);
  present();
}

void Ui::drawHeader(const UiState& st, const findmy::TrackerRegistry& reg) {
  g().fillRect(0, 0, kW, kHeaderH, COLOR_HEADER);
  char left[24];
  snprintf(left, sizeof(left), "AIRTAG %s", pageName(st.page));
  text(6, 6, left, COLOR_TEXT, COLOR_HEADER);
  char right[24];
  snprintf(right, sizeof(right), "%u tags %u sep", (unsigned)reg.size(), (unsigned)reg.separatedCount());
  text(kW - 6 - (int)strlen(right) * kCharW, 6, right, COLOR_DIM, COLOR_HEADER);
}

void Ui::drawFooter(const char* hints) {
  g().fillRect(0, kH - kFooterH, kW, kFooterH, COLOR_FOOTER);
  text(6, kH - 11, hints, COLOR_DIM, COLOR_FOOTER);
}

void Ui::drawFooterStatus(const UiState& st) {
  int x = kW - 6;
  char batt[8];
  const int level = M5Cardputer.Power.getBatteryLevel();
  if (level >= 0) snprintf(batt, sizeof(batt), "%d%%", level);
  else snprintf(batt, sizeof(batt), "--%%");
  x -= (int)strlen(batt) * kCharW;
  text(x, kH - 11, batt, COLOR_ACCENT, COLOR_FOOTER);
  x -= 2 * kCharW;
  const char spin[2] = {st.bleError ? 'X' : kSpinner[spinner_ & 3], '\0'};
  spinner_++;
  text(x, kH - 11, spin, st.bleError ? COLOR_BAD : COLOR_GOOD, COLOR_FOOTER);
  if (st.sdWarning) {
    x -= 4 * kCharW;
    text(x, kH - 11, "SD!", COLOR_WARN, COLOR_FOOTER);
  }
}

void Ui::drawRssiCells(int x, int y, float rssiEma, uint16_t color) {
  const int lit = rssiCells(rssiEma);
  for (int i = 0; i < 5; ++i) g().fillRect(x + i * 5, y, 4, 7, i < lit ? color : COLOR_PANEL);
}

void Ui::drawRadar(const UiState& st, const findmy::TrackerRegistry& reg, uint32_t nowMs) {
  int slots[findmy::TrackerRegistry::kCapacity];
  const int count = (int)reg.sortedByRssi(slots, findmy::TrackerRegistry::kCapacity);
  if (count == 0) {
    text(8, 44, "Listening for Find My tags...", COLOR_DIM, COLOR_BG);
    text(8, 60, "AirTags advertise about every 2 s.", COLOR_DIM, COLOR_BG);
    drawFooter("<> page  ` return");
    return;
  }
  const int sel = clampSel(st.radarSel, count);
  const int first = firstVisible(sel, kRows);
  LovyanGFX& d = g();
  for (int row = 0; row < kRows && first + row < count; ++row) {
    const findmy::Entry& e = *reg.at(slots[first + row]);
    const bool selected = first + row == sel;
    const bool stale = nowMs - e.lastSeenMs > 30000;
    const int y = kRowY0 + row * kRowH;
    const uint16_t bg = selected ? COLOR_SELECTED : COLOR_BG;
    const uint16_t fg = selected ? COLOR_SELECTED_TEXT : (stale ? COLOR_DIM : COLOR_TEXT);
    d.fillRoundRect(2, y, kW - 4, kRowH - 1, 3, bg);
    text(6, y + 4, e.alerted ? "!" : " ", selected ? COLOR_SELECTED_TEXT : COLOR_BAD, bg);
    text(18, y + 4, findmy::deviceClassShort(e.deviceClass), fg, bg);
    char id[5];
    shortId(e.mac, id);
    text(38, y + 4, id, fg, bg);
    const uint16_t modeColor = selected ? COLOR_SELECTED_TEXT
                               : (e.mode == findmy::Mode::Separated ? COLOR_WARN : (stale ? COLOR_DIM : COLOR_GOOD));
    text(70, y + 4, findmy::modeLabel(e.mode), modeColor, bg);
    drawRssiCells(102, y + 4, e.rssiEma, selected ? COLOR_SELECTED_TEXT : COLOR_ACCENT);
    char dbm[8];
    snprintf(dbm, sizeof(dbm), "%4ld", lroundf(e.rssiEma));
    text(132, y + 4, dbm, fg, bg);
    char presence[findmy::kPresenceStrLen];
    findmy::formatPresence(nowMs - e.presenceStartMs, presence);
    text(170, y + 4, presence, fg, bg);
  }
  drawFooter("^v sel  Enter info  <> pg");
}

void Ui::drawBleError(const UiState& st) {
  text(8, 36, "BLE scan failed:", COLOR_BAD, COLOR_BG);
  text(8, 52, st.bleErrorText, COLOR_TEXT, COLOR_BG);
  text(8, 76, "Settings > Return to Cypher OS", COLOR_DIM, COLOR_BG);
  drawFooter("<> page  ` return");
}

void Ui::drawAlerts(const UiState& st, const findmy::TrackerRegistry& reg, const Settings& settings,
                    const AlertRecord* alerts, size_t alertCount, uint32_t nowMs) {
  if (alertCount == 0) {
    char line[48];
    snprintf(line, sizeof(line), "Separated tags present >= %u min", (unsigned)settings.thresholdMin);
    text(8, 44, "No alerts.", COLOR_DIM, COLOR_BG);
    text(8, 60, line, COLOR_DIM, COLOR_BG);
    text(8, 72, "appear here.", COLOR_DIM, COLOR_BG);
    drawFooter("<> page");
    return;
  }
  const int count = (int)alertCount;
  const int sel = clampSel(st.alertSel, count);
  const int first = firstVisible(sel, kRows);
  LovyanGFX& d = g();
  for (int row = 0; row < kRows && first + row < count; ++row) {
    const AlertRecord& a = alerts[first + row];
    const findmy::Entry* e = reg.find(a.mac);
    const bool selected = first + row == sel;
    const int y = kRowY0 + row * kRowH;
    const uint16_t bg = selected ? COLOR_SELECTED : COLOR_BG;
    const uint16_t fg = selected ? COLOR_SELECTED_TEXT : (e != nullptr ? COLOR_TEXT : COLOR_DIM);
    d.fillRoundRect(2, y, kW - 4, kRowH - 1, 3, bg);
    text(6, y + 4, findmy::deviceClassShort(a.deviceClass), fg, bg);
    char id[5];
    shortId(a.mac, id);
    text(26, y + 4, id, fg, bg);
    char presence[findmy::kPresenceStrLen];
    findmy::formatPresence(e != nullptr ? nowMs - e->presenceStartMs : a.presenceMs, presence);
    text(62, y + 4, presence, fg, bg);
    char dbm[8];
    snprintf(dbm, sizeof(dbm), "%4ld", e != nullptr ? lroundf(e->rssiEma) : (long)a.rssi);
    text(98, y + 4, dbm, fg, bg);
    char ago[findmy::kAgoStrLen];
    findmy::formatAgo(nowMs - a.atMs, ago);
    text(140, y + 4, ago, selected ? COLOR_SELECTED_TEXT : COLOR_DIM, bg);
  }
  drawFooter("Enter info  M mute  <> pg");
}

void Ui::drawSettings(const UiState& st, const Settings& settings) {
  const char* labels[kSettingsRowCount] = {"Alert threshold", "Sound", "SD log", "Serial JSON",
                                           "Return to Cypher OS", "About"};
  char values[kSettingsRowCount][12];
  snprintf(values[0], sizeof(values[0]), "%u min", (unsigned)settings.thresholdMin);
  snprintf(values[1], sizeof(values[1]), "%s", settings.sound ? "on" : "off");
  snprintf(values[2], sizeof(values[2]), "%s", settings.sdLog ? "on" : "off");
  snprintf(values[3], sizeof(values[3]), "%s", settings.serialJson ? "on" : "off");
  values[4][0] = '\0';
  values[5][0] = '\0';
  const int sel = clampSel(st.settingsSel, kSettingsRowCount);
  LovyanGFX& d = g();
  for (int row = 0; row < kSettingsRowCount; ++row) {
    const bool selected = row == sel;
    const int y = kRowY0 + row * kRowH;
    const uint16_t bg = selected ? COLOR_SELECTED : COLOR_BG;
    const uint16_t fg = selected ? COLOR_SELECTED_TEXT : COLOR_TEXT;
    d.fillRoundRect(2, y, kW - 4, kRowH - 1, 3, bg);
    text(8, y + 4, selected ? ">" : " ", fg, bg);
    text(20, y + 4, labels[row], fg, bg);
    if (values[row][0] != '\0') {
      text(kW - 8 - (int)strlen(values[row]) * kCharW, y + 4, values[row],
           selected ? COLOR_SELECTED_TEXT : COLOR_ACCENT, bg);
    }
  }
  drawFooter("^v sel Enter change <> pg");
}

void Ui::drawDetail(const UiState& st, const findmy::TrackerRegistry& reg, uint32_t nowMs) {
  const findmy::Entry* e = st.detailValid ? reg.find(st.detailMac) : nullptr;
  if (e == nullptr) {
    text(8, 44, "lost - press back", COLOR_WARN, COLOR_BG);
    drawFooter("Del back");
    return;
  }
  LovyanGFX& d = g();
  char line[48];
  char mac[findmy::kMacStrLen];
  findmy::formatMac(e->mac, mac);
  snprintf(line, sizeof(line), "MAC %s", mac);
  text(8, 24, line, COLOR_TEXT, COLOR_BG);
  snprintf(line, sizeof(line), "%s %s  batt %s", findmy::deviceClassShort(e->deviceClass),
           findmy::deviceClassLabel(e->deviceClass), findmy::batteryLabel(e->battery));
  text(8, 36, line, COLOR_ACCENT, COLOR_BG);
  snprintf(line, sizeof(line), "mode %s  status 0x%02X  advs %lu", findmy::modeLabel(e->mode),
           (unsigned)e->status, (unsigned long)e->advCount);
  text(8, 48, line, e->mode == findmy::Mode::Separated ? COLOR_WARN : COLOR_GOOD, COLOR_BG);
  char first[findmy::kAgoStrLen];
  char last[findmy::kAgoStrLen];
  findmy::formatAgo(nowMs - e->firstSeenMs, first);
  findmy::formatAgo(nowMs - e->lastSeenMs, last);
  snprintf(line, sizeof(line), "first %s  last %s", first, last);
  text(8, 60, line, COLOR_DIM, COLOR_BG);
  if (e->hasKey) {
    uint8_t key[findmy::kKeyLen];
    findmy::assembleKey(e->mac, e->keyBits, e->keyTail, key);
    char hex[findmy::kKeyHexLen];
    findmy::formatKeyHex(key, hex);
    snprintf(line, sizeof(line), "key %.16s..", hex);
  } else {
    snprintf(line, sizeof(line), "%s", "key none (nearby)");
  }
  text(8, 72, line, COLOR_DIM, COLOR_BG);
  // Continuous RSSI bar: -95 dBm empty .. -35 dBm full, 150 px wide.
  float t = (e->rssiEma + 95.0f) / 60.0f;
  if (t < 0.0f) t = 0.0f;
  if (t > 1.0f) t = 1.0f;
  d.fillRect(8, 88, 150, 10, COLOR_PANEL);
  d.fillRect(8, 88, (int)(t * 150.0f), 10, COLOR_ACCENT);
  snprintf(line, sizeof(line), "%ld dBm", lroundf(e->rssiEma));
  text(166, 89, line, COLOR_TEXT, COLOR_BG);
  if (st.locate) text(8, 104, "LOCATE ON - beeps faster when closer", COLOR_GOOD, COLOR_BG);
  else text(8, 104, "Space: locate beeps   M: mute alerts", COLOR_DIM, COLOR_BG);
  drawFooter("Spc locate  M mute  Del bk");
}

void Ui::drawAbout(const UiState& st, uint32_t nowMs) {
  char line[48];
  snprintf(line, sizeof(line), "Cypher AirTag v%s", CYPHER_AIRTAG_VERSION);
  text(8, 24, line, COLOR_ACCENT, COLOR_BG);
  char uptime[findmy::kPresenceStrLen];
  findmy::formatPresence(nowMs, uptime);
  snprintf(line, sizeof(line), "session %lu  uptime %s", (unsigned long)st.session, uptime);
  text(8, 36, line, COLOR_TEXT, COLOR_BG);
  snprintf(line, sizeof(line), "adverts %lu  dropped %lu", (unsigned long)st.queueReceived,
           (unsigned long)st.queueDropped);
  text(8, 48, line, COLOR_TEXT, COLOR_BG);
  snprintf(line, sizeof(line), "evictions %lu  heap %lu", (unsigned long)st.evictions,
           (unsigned long)ESP.getFreeHeap());
  text(8, 60, line, COLOR_TEXT, COLOR_BG);
  snprintf(line, sizeof(line), "SD %s  launcher %s", st.sdLabel, st.launcherReturn ? "yes" : "no");
  text(8, 72, line, COLOR_TEXT, COLOR_BG);
  text(8, 90, "Passive BLE listening only.", COLOR_DIM, COLOR_BG);
  text(8, 102, "Use where lawful and authorized.", COLOR_DIM, COLOR_BG);
  drawFooter("Del back");
}

void Ui::drawOverlay(const UiState& st) {
  LovyanGFX& d = g();
  const int x = 10, y = 30, w = kW - 20, h = 72;
  d.fillRoundRect(x, y, w, h, 4, COLOR_PANEL);
  d.drawRoundRect(x, y, w, h, 4, COLOR_BAD);
  char line[40];
  char presence[findmy::kPresenceStrLen];
  findmy::formatPresence(st.overlayAlert.presenceMs, presence);
  snprintf(line, sizeof(line), "SEPARATED TAG PRESENT %s", presence);
  text(x + 8, y + 8, line, COLOR_BAD, COLOR_PANEL);
  char id[5];
  shortId(st.overlayAlert.mac, id);
  snprintf(line, sizeof(line), "%s %s   %d dBm", findmy::deviceClassLabel(st.overlayAlert.deviceClass), id,
           (int)st.overlayAlert.rssi);
  text(x + 8, y + 28, line, COLOR_TEXT, COLOR_PANEL);
  text(x + 8, y + 52, "Enter view  M mute  Del dismiss", COLOR_DIM, COLOR_PANEL);
}

void Ui::drawConfirm() {
  LovyanGFX& d = g();
  const int x = 20, y = 40, w = kW - 40, h = 52;
  d.fillRoundRect(x, y, w, h, 4, COLOR_PANEL);
  d.drawRoundRect(x, y, w, h, 4, COLOR_ACCENT);
  text(x + 10, y + 10, "Return to Cypher OS?", COLOR_TEXT, COLOR_PANEL);
  text(x + 10, y + 30, "Enter yes    Del no", COLOR_DIM, COLOR_PANEL);
}
```

- [ ] **Step 3: Build for the device (the placeholder sketch does not use Ui yet, but Arduino compiles every file under `src/`)**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && tools/build.sh
```
Expected: `[build] ok ...`. If `M5Canvas canvas_;` fails to default-construct, change the member to `M5Canvas canvas_{nullptr};`.

- [ ] **Step 4: Commit**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && git add -A && \
git commit -q -m "feat(device): render radar, alerts, settings, detail, about, and overlays

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" && git log --oneline -1
```

---

### Task 10: `app` — wire everything, real `.ino`, first full device build

**Files:**
- Create: `$APP/src/device/app.h`, `$APP/src/device/app.cpp`
- Modify: `$APP/cypher-airtag.ino` (replace the placeholder)

- [ ] **Step 1: Write `src/device/app.h`**

```cpp
#pragma once
// Owns every module. loop(): drain BLE sightings, run 1 s periodic work, route input, tick sound, draw.
#include <stddef.h>
#include <stdint.h>

#include "../core/follow_detector.h"
#include "../core/tracker_registry.h"
#include "ble_scanner.h"
#include "event_log.h"
#include "input.h"
#include "settings.h"
#include "sound.h"
#include "ui.h"

class App {
 public:
  void begin();
  void loop();

 private:
  static constexpr size_t kAlertHistory = 16;
  static constexpr uint32_t kPeriodicMs = 1000;
  static constexpr uint32_t kUpdateLogMs = 60000;
  static constexpr uint32_t kRedrawMs = 250;
  static constexpr uint32_t kLocateFreshMs = 5000;
  static constexpr size_t kSerialLineLen = 32;

  void drainSightings(uint32_t nowMs);
  void periodic(uint32_t nowMs);
  void handleSerial();
  void handleInput(const InputEvent& ev, uint32_t nowMs);
  void handleOverlay(const InputEvent& ev, uint32_t nowMs);
  void handleConfirm(const InputEvent& ev);
  void handleRadar(const InputEvent& ev);
  void handleAlerts(const InputEvent& ev, uint32_t nowMs);
  void handleSettings(const InputEvent& ev);
  void handleDetail(const InputEvent& ev, uint32_t nowMs);
  void handleAbout(const InputEvent& ev);
  void switchPage(int direction);
  void openDetail(const uint8_t mac[6], Page from);
  void closeDetail();
  void muteMac(const uint8_t mac[6], uint32_t nowMs);
  void pushAlert(const findmy::FollowDetector::Alert& a, uint32_t nowMs);
  void removeAlert(const uint8_t mac[6]);
  void locateTick(uint32_t nowMs);
  void refreshDiagnostics();
  void applySettings();
  void printStatus();
  void doReturnToLauncher();

  findmy::TrackerRegistry registry_;
  findmy::FollowDetector detector_;
  BleScanner scanner_;
  EventLog log_;
  Settings settings_;
  Sound sound_;
  Ui ui_;
  UiState state_;
  AlertRecord alerts_[kAlertHistory] = {};
  size_t alertCount_ = 0;
  EventLog::SdState lastSdState_ = EventLog::SdState::Off;
  char serialLine_[kSerialLineLen] = "";
  size_t serialLen_ = 0;
  uint32_t lastPeriodicMs_ = 0;
  uint32_t lastDrawMs_ = 0;
  bool dirty_ = true;
};
```

- [ ] **Step 2: Write `src/device/app.cpp`**

```cpp
#include "app.h"

#include <Arduino.h>
#include <M5Cardputer.h>
#include <string.h>

#include "launcher_return.h"
#include "version.h"

namespace {
constexpr uint32_t kSerialBaud = 115200;
constexpr uint8_t kBrightness = 180;
constexpr int kPageCount = 3;  // Radar, Alerts, Settings cycle with left/right

int pageIndex(Page p) {
  switch (p) {
    case Page::Alerts: return 1;
    case Page::Settings: return 2;
    default: return 0;
  }
}

Page pageAt(int index) {
  const Page pages[kPageCount] = {Page::Radar, Page::Alerts, Page::Settings};
  return pages[((index % kPageCount) + kPageCount) % kPageCount];
}
}  // namespace

void App::begin() {
  Serial.begin(kSerialBaud);
  Serial.setTxTimeoutMs(0);  // never block the loop when no host is attached
  auto cfg = M5.config();
  M5Cardputer.begin(cfg, true);
  M5Cardputer.Display.setRotation(1);
  M5Cardputer.Display.setBrightness(kBrightness);
  sound_.begin();
  settings_.load();
  applySettings();
  ui_.begin();
  ui_.drawMessage("Cypher AirTag", "Starting BLE scan...");
  log_.begin(settings_.boots, settings_.sdLog, settings_.serialJson);
  lastSdState_ = log_.sdState();
  if (!scanner_.begin()) {
    state_.bleError = true;
    strlcpy(state_.bleErrorText, scanner_.lastError(), sizeof(state_.bleErrorText));
  }
  state_.session = settings_.boots;
  state_.launcherReturn = launcherReturnAvailable();
  log_.logBoot(CYPHER_AIRTAG_VERSION, settings_.thresholdMin, millis());
  dirty_ = true;
}

void App::applySettings() {
  detector_.setThresholdMs(settings_.thresholdMs());
  sound_.setEnabled(settings_.sound);
  log_.setSerialEnabled(settings_.serialJson);
}

void App::loop() {
  M5Cardputer.update();
  const uint32_t now = millis();
  drainSightings(now);
  if (now - lastPeriodicMs_ >= kPeriodicMs) {
    periodic(now);
    lastPeriodicMs_ = now;
  }
  handleSerial();
  const InputEvent ev = readInput();
  if (ev.any) {
    handleInput(ev, now);
    dirty_ = true;
  }
  locateTick(now);
  sound_.tick(now);
  if (dirty_ || now - lastDrawMs_ >= kRedrawMs) {
    refreshDiagnostics();
    ui_.draw(state_, registry_, settings_, alerts_, alertCount_, now);
    dirty_ = false;
    lastDrawMs_ = now;
  }
  delay(10);
}

void App::drainSightings(uint32_t nowMs) {
  findmy::Sighting s;
  for (int budget = 0; budget < 64 && scanner_.poll(s); ++budget) {
    const findmy::ObserveResult r = registry_.observe(s, nowMs);
    if (r.index < 0) continue;
    const findmy::Entry& e = *registry_.at(static_cast<size_t>(r.index));
    if (r.isNew) log_.logSeen(e, nowMs);
    else if (r.modeChanged) log_.logMode(e, r.previousMode, nowMs);
    dirty_ = true;
  }
}

void App::periodic(uint32_t nowMs) {
  findmy::Entry lost[8];
  const size_t lostCount = registry_.expire(nowMs, lost, 8);
  for (size_t i = 0; i < lostCount && i < 8; ++i) {
    log_.logLost(lost[i], nowMs);
    if (state_.detailValid && findmy::macEquals(lost[i].mac, state_.detailMac)) {
      state_.locate = false;
      sound_.stopLocate();
    }
  }

  findmy::FollowDetector::Alert fresh[4];
  const size_t alertCount = detector_.evaluate(registry_, nowMs, fresh, 4);
  for (size_t i = 0; i < alertCount; ++i) {
    log_.logAlert(fresh[i], nowMs);
    pushAlert(fresh[i], nowMs);
    state_.overlay = true;
    state_.overlayAlert = alerts_[0];
    sound_.alertChirps();
  }

  for (size_t slot = 0; slot < findmy::TrackerRegistry::kCapacity; ++slot) {
    findmy::Entry* e = registry_.at(slot);
    if (e != nullptr && nowMs - e->lastUpdateLogMs >= kUpdateLogMs) {
      log_.logUpdate(*e, nowMs);
      e->lastUpdateLogMs = nowMs;
    }
  }

  if (log_.sdState() != lastSdState_) {
    lastSdState_ = log_.sdState();
    log_.logSd(nowMs);
  }
  if (lostCount > 0 || alertCount > 0) dirty_ = true;
}

// Minimal serial console, matching the WireTap-32 / Bit Pirate convention: "return" or
// "launcher" reboots into Cypher OS, "status" prints a one-line summary, "help" lists commands.
void App::handleSerial() {
  while (Serial.available() > 0) {
    const char c = static_cast<char>(Serial.read());
    if (c == '\r') continue;
    if (c != '\n') {
      if (serialLen_ + 1 < kSerialLineLen) serialLine_[serialLen_++] = c;
      continue;
    }
    serialLine_[serialLen_] = '\0';
    serialLen_ = 0;
    if (strcmp(serialLine_, "return") == 0 || strcmp(serialLine_, "launcher") == 0) {
      doReturnToLauncher();
    } else if (strcmp(serialLine_, "status") == 0) {
      printStatus();
    } else if (strcmp(serialLine_, "help") == 0) {
      Serial.println("commands: help, status, return, launcher");
    }
  }
}

void App::printStatus() {
  refreshDiagnostics();
  Serial.printf("{\"ev\":\"status\",\"fw\":\"%s\",\"tags\":%u,\"sep\":%u,\"alerts\":%u,\"adverts\":%lu,\"dropped\":%lu,"
                "\"sd\":\"%s\",\"thresh_min\":%u,\"ble_ok\":%s}\n",
                CYPHER_AIRTAG_VERSION, (unsigned)registry_.size(), (unsigned)registry_.separatedCount(),
                (unsigned)alertCount_, (unsigned long)state_.queueReceived, (unsigned long)state_.queueDropped,
                state_.sdLabel, (unsigned)settings_.thresholdMin, state_.bleError ? "false" : "true");
}

void App::handleInput(const InputEvent& ev, uint32_t nowMs) {
  if (state_.overlay) {
    handleOverlay(ev, nowMs);
    return;
  }
  if (state_.confirmReturn) {
    handleConfirm(ev);
    return;
  }
  switch (state_.page) {
    case Page::Radar: handleRadar(ev); break;
    case Page::Alerts: handleAlerts(ev, nowMs); break;
    case Page::Settings: handleSettings(ev); break;
    case Page::Detail: handleDetail(ev, nowMs); break;
    case Page::About: handleAbout(ev); break;
  }
}

void App::handleOverlay(const InputEvent& ev, uint32_t nowMs) {
  if (ev.select) {
    state_.overlay = false;
    openDetail(state_.overlayAlert.mac, state_.page == Page::Detail ? state_.returnPage : state_.page);
  } else if (ev.mute) {
    muteMac(state_.overlayAlert.mac, nowMs);
    state_.overlay = false;
  } else if (ev.back) {
    state_.overlay = false;
  }
}

void App::handleConfirm(const InputEvent& ev) {
  if (ev.select) doReturnToLauncher();
  else if (ev.back) state_.confirmReturn = false;
}

void App::switchPage(int direction) {
  state_.page = pageAt(pageIndex(state_.page) + direction);
}

void App::handleRadar(const InputEvent& ev) {
  if (ev.left) { switchPage(-1); return; }
  if (ev.right) { switchPage(+1); return; }
  if (ev.back) { state_.confirmReturn = true; return; }
  int slots[findmy::TrackerRegistry::kCapacity];
  const int count = static_cast<int>(registry_.sortedByRssi(slots, findmy::TrackerRegistry::kCapacity));
  if (count == 0) return;
  if (state_.radarSel >= count) state_.radarSel = count - 1;
  if (ev.up) state_.radarSel = (state_.radarSel + count - 1) % count;
  if (ev.down) state_.radarSel = (state_.radarSel + 1) % count;
  if (ev.select) openDetail(registry_.at(static_cast<size_t>(slots[state_.radarSel]))->mac, Page::Radar);
}

void App::handleAlerts(const InputEvent& ev, uint32_t nowMs) {
  if (ev.left) { switchPage(-1); return; }
  if (ev.right) { switchPage(+1); return; }
  const int count = static_cast<int>(alertCount_);
  if (count == 0) return;
  if (state_.alertSel >= count) state_.alertSel = count - 1;
  if (ev.up) state_.alertSel = (state_.alertSel + count - 1) % count;
  if (ev.down) state_.alertSel = (state_.alertSel + 1) % count;
  if (ev.select) openDetail(alerts_[state_.alertSel].mac, Page::Alerts);
  else if (ev.mute) muteMac(alerts_[state_.alertSel].mac, nowMs);
}

void App::handleSettings(const InputEvent& ev) {
  if (ev.left) { switchPage(-1); return; }
  if (ev.right) { switchPage(+1); return; }
  if (ev.up) state_.settingsSel = (state_.settingsSel + kSettingsRowCount - 1) % kSettingsRowCount;
  if (ev.down) state_.settingsSel = (state_.settingsSel + 1) % kSettingsRowCount;
  if (!ev.select) return;
  switch (state_.settingsSel) {
    case 0:
      settings_.cycleThreshold();
      settings_.save();
      applySettings();
      break;
    case 1:
      settings_.sound = !settings_.sound;
      settings_.save();
      applySettings();
      break;
    case 2:
      settings_.sdLog = !settings_.sdLog;
      settings_.save();
      log_.setSdEnabled(settings_.sdLog);
      break;
    case 3:
      settings_.serialJson = !settings_.serialJson;
      settings_.save();
      applySettings();
      break;
    case 4:
      state_.confirmReturn = true;
      break;
    case 5:
      state_.page = Page::About;
      break;
    default:
      break;
  }
}

void App::handleDetail(const InputEvent& ev, uint32_t nowMs) {
  if (ev.back) {
    closeDetail();
    return;
  }
  if (ev.space) {
    state_.locate = !state_.locate;
    if (state_.locate) sound_.startLocate();
    else sound_.stopLocate();
  }
  if (ev.mute) muteMac(state_.detailMac, nowMs);
}

void App::handleAbout(const InputEvent& ev) {
  if (ev.back || ev.select) state_.page = Page::Settings;
}

void App::openDetail(const uint8_t mac[6], Page from) {
  memcpy(state_.detailMac, mac, 6);
  state_.detailValid = true;
  state_.returnPage = from;
  state_.page = Page::Detail;
}

void App::closeDetail() {
  state_.locate = false;
  sound_.stopLocate();
  state_.page = state_.returnPage;
}

void App::muteMac(const uint8_t mac[6], uint32_t nowMs) {
  detector_.mute(mac);
  findmy::Entry* e = registry_.find(mac);
  if (e != nullptr) e->alerted = false;
  removeAlert(mac);
  log_.logMute(mac, nowMs);
  if (state_.overlay && findmy::macEquals(state_.overlayAlert.mac, mac)) state_.overlay = false;
}

void App::pushAlert(const findmy::FollowDetector::Alert& a, uint32_t nowMs) {
  removeAlert(a.mac);
  if (alertCount_ < kAlertHistory) alertCount_++;
  for (size_t i = alertCount_ - 1; i > 0; --i) alerts_[i] = alerts_[i - 1];
  memcpy(alerts_[0].mac, a.mac, 6);
  alerts_[0].atMs = nowMs;
  alerts_[0].presenceMs = a.presenceMs;
  alerts_[0].rssi = a.rssi;
  alerts_[0].deviceClass = a.deviceClass;
}

void App::removeAlert(const uint8_t mac[6]) {
  size_t write = 0;
  for (size_t read = 0; read < alertCount_; ++read) {
    if (findmy::macEquals(alerts_[read].mac, mac)) continue;
    alerts_[write++] = alerts_[read];
  }
  alertCount_ = write;
}

void App::locateTick(uint32_t nowMs) {
  if (!state_.locate) return;
  const findmy::Entry* e = registry_.find(state_.detailMac);
  if (e == nullptr) {
    state_.locate = false;
    sound_.stopLocate();
    return;
  }
  sound_.setLocateRssi(e->rssiEma, nowMs - e->lastSeenMs < kLocateFreshMs);
}

void App::refreshDiagnostics() {
  state_.queueReceived = scanner_.received();
  state_.queueDropped = scanner_.dropped();
  state_.evictions = registry_.evictions();
  state_.sdLabel = log_.sdStateLabel();
  state_.sdWarning = log_.sdWarning();
}

void App::doReturnToLauncher() {
  ui_.drawMessage("Cypher AirTag", "Returning to Cypher OS...");
  returnToLauncher();
}
```

- [ ] **Step 3: Replace `cypher-airtag.ino`**

```cpp
// Cypher AirTag: passive Apple Find My / AirTag detector for the M5Stack Cardputer ADV.
// Everything lives in src/device/app.*; this file only hands control to it.
#include "src/device/app.h"

static App* app = nullptr;

void setup() {
  app = new App();
  app->begin();
}

void loop() {
  app->loop();
}
```

- [ ] **Step 4: Host tests still pass, then build for the device**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && tools/run-host-tests.sh && tools/build.sh
```
Expected: `36 tests, 0 failures` then `[build] ok cypher-airtag.ino.bin <n> bytes` with n well under 5,177,344 (the app1 slot).

- [ ] **Step 5: Commit**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && git add -A && \
git commit -q -m "feat: wire App state machine, serial console, and sketch entry point

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" && git log --oneline -1
```

---

### Task 11: Cypher OS integration — catalog, build scripts, docs

**Files:**
- Modify: `$OS/config/apps.json`, `$OS/tools/build-apps.sh`, `$OS/tools/build-report.py`, `$OS/tools/package-sd.sh`, `$OS/docs/README.md`, `$OS/docs/APP_CATALOG.md`, `$OS/docs/BUILDING_AND_PACKAGING.md`, `$OS/README.md`, `$OS/AGENTS.md`
- Create: `$OS/docs/apps/cypher-airtag/README.md`

- [ ] **Step 1: Add the catalog entry**

```bash
cd /Users/cypher/Documents/GitHub/cypher-puter-os && python3 - <<'PY'
import json, pathlib
p = pathlib.Path("config/apps.json")
data = json.loads(p.read_text())
apps = data["apps"]
assert not any(a["slug"] == "cypher-airtag" for a in apps)
idx = next(i for i, a in enumerate(apps) if a["slug"] == "drone-mesh-mapper") + 1
apps.insert(idx, {
    "name": "Cypher AirTag",
    "slug": "cypher-airtag",
    "binary": "cypher-airtag.bin",
    "repo_url": "https://github.com/dkyazzentwatwa/cypher-airtag",
    "local_default_path": "../cypher-airtag",
    "build_profile": "cardputer-adv",
    "sd_paths": ["/cypher-airtag/"],
    "return_to_launcher": "Choose Return to Cypher OS on the Settings page, press backtick on the Radar page and confirm with Enter, or type return over serial.",
    "public_release": True,
    "status": "ready",
    "notes": "Cardputer ADV passive Apple Find My / AirTag detector with following alerts, locate beeps, SD JSONL logs, and Cypher OS return support."
})
p.write_text(json.dumps(data, indent=2) + "\n")
print("catalog entry added")
PY
git diff --stat config/apps.json
```
Expected: `catalog entry added` and a diff of about 15 insertions, 0 deletions (the file's existing formatting is preserved).

- [ ] **Step 2: Wire `tools/build-apps.sh`**

```bash
cd /Users/cypher/Documents/GitHub/cypher-puter-os && python3 - <<'PY'
import pathlib
p = pathlib.Path("tools/build-apps.sh"); s = p.read_text()
def once(old, new):
    global s
    assert s.count(old) == 1, old
    s = s.replace(old, new)
once("|drone-mesh-mapper|bitcoin-card-wallet|", "|drone-mesh-mapper|cypher-airtag|bitcoin-card-wallet|")
once('DRONE_MESH_MAPPER_ROOT="${CYPHER_OS_DRONE_MESH_MAPPER_DIR:-${WORKSPACE_ROOT}/drone-mesh-mapper}"\n',
     'DRONE_MESH_MAPPER_ROOT="${CYPHER_OS_DRONE_MESH_MAPPER_DIR:-${WORKSPACE_ROOT}/drone-mesh-mapper}"\n'
     'CYPHER_AIRTAG_ROOT="${CYPHER_OS_CYPHER_AIRTAG_DIR:-${WORKSPACE_ROOT}/cypher-airtag}"\n')
once('DRONE_MESH_MAPPER_STATUS="build_missing"\n',
     'DRONE_MESH_MAPPER_STATUS="build_missing"\nCYPHER_AIRTAG_STATUS="build_missing"\n')
once('    drone-mesh-mapper) DRONE_MESH_MAPPER_STATUS="${status}" ;;\n',
     '    drone-mesh-mapper) DRONE_MESH_MAPPER_STATUS="${status}" ;;\n    cypher-airtag) CYPHER_AIRTAG_STATUS="${status}" ;;\n')
once('    drone-mesh-mapper) echo "${DRONE_MESH_MAPPER_STATUS}" ;;\n',
     '    drone-mesh-mapper) echo "${DRONE_MESH_MAPPER_STATUS}" ;;\n    cypher-airtag) echo "${CYPHER_AIRTAG_STATUS}" ;;\n')
once('    drone-mesh-mapper) DRONE_MESH_MAPPER_STATUS="build_failed" ;;\n',
     '    drone-mesh-mapper) DRONE_MESH_MAPPER_STATUS="build_failed" ;;\n    cypher-airtag) CYPHER_AIRTAG_STATUS="build_failed" ;;\n')
once('build_bitcoin_card_wallet() {\n', '''build_cypher_airtag() {
  local src="${CYPHER_AIRTAG_ROOT}"
  local out="${BUILD_ROOT}/cypher-airtag"
  require_dir "cypher-airtag source" "${src}" || return 1
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "[apps] building cypher-airtag"
  arduino-cli compile \\
    --profile cardputer-adv \\
    --output-dir "${out}" \\
    --build-property "compiler.cpp.extra_flags=-I${RETURN_LIB}/src" \\
    "${src}" || return 1
  copy_app_bin "${out}" "cypher-airtag.bin" || return 1
  CYPHER_AIRTAG_STATUS="ready"
}

build_bitcoin_card_wallet() {
''')
once('run_build "drone-mesh-mapper" build_drone_mesh_mapper\n',
     'run_build "drone-mesh-mapper" build_drone_mesh_mapper\nrun_build "cypher-airtag" build_cypher_airtag\n')
once('DRONE_MESH_MAPPER_STATUS="${DRONE_MESH_MAPPER_STATUS}" \\\n',
     'DRONE_MESH_MAPPER_STATUS="${DRONE_MESH_MAPPER_STATUS}" \\\nCYPHER_AIRTAG_STATUS="${CYPHER_AIRTAG_STATUS}" \\\n')
once('DRONE_MESH_MAPPER_ROOT="${DRONE_MESH_MAPPER_ROOT}" \\\n',
     'DRONE_MESH_MAPPER_ROOT="${DRONE_MESH_MAPPER_ROOT}" \\\nCYPHER_AIRTAG_ROOT="${CYPHER_AIRTAG_ROOT}" \\\n')
once('"${DRONE_MESH_MAPPER_STATUS}" != "ready" || "${BITCOIN_CARD_WALLET_STATUS}" != "ready"',
     '"${DRONE_MESH_MAPPER_STATUS}" != "ready" || "${CYPHER_AIRTAG_STATUS}" != "ready" || "${BITCOIN_CARD_WALLET_STATUS}" != "ready"')
p.write_text(s); print("build-apps.sh wired")
PY
bash -n tools/build-apps.sh && echo "syntax ok"
```
Expected: `build-apps.sh wired` and `syntax ok`.

- [ ] **Step 3: Wire `tools/build-report.py` and `tools/package-sd.sh`**

```bash
cd /Users/cypher/Documents/GitHub/cypher-puter-os && python3 - <<'PY'
import pathlib
p = pathlib.Path("tools/build-report.py"); s = p.read_text()
old = '    "drone-mesh-mapper": ("DRONE_MESH_MAPPER_STATUS", "DRONE_MESH_MAPPER_ROOT"),\n'
assert s.count(old) == 1
s = s.replace(old, old + '    "cypher-airtag": ("CYPHER_AIRTAG_STATUS", "CYPHER_AIRTAG_ROOT"),\n')
old = '            "- Drone Mesh Mapper SD seed assets are packaged under `/drone/` when present.",\n'
assert s.count(old) == 1
s = s.replace(old, old + '            "- Cypher AirTag writes JSONL detections under `/cypher-airtag/logs/` when SD logging is enabled.",\n')
p.write_text(s)

p = pathlib.Path("tools/package-sd.sh"); s = p.read_text()
old = 'mkdir -p "${SD_APPS}" "${SD_GAME_OS_SAVES}" "${NEWS_READER_CONFIG_DIR}"\n'
assert s.count(old) == 1
s = s.replace(old, old + 'mkdir -p "${SD_ROOT}/cypher-airtag/logs"\n')
p.write_text(s)
print("report + sd wired")
PY
python3 -m py_compile tools/build-report.py && bash -n tools/package-sd.sh && echo "syntax ok"
```
Expected: `report + sd wired` and `syntax ok`.

- [ ] **Step 4: Write `docs/apps/cypher-airtag/README.md`**

```markdown
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
prints a JSON summary.

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
```

- [ ] **Step 5: Add the doc links, catalog row, README rows, env overrides, and AGENTS.md status**

```bash
cd /Users/cypher/Documents/GitHub/cypher-puter-os && python3 - <<'PY'
import pathlib
def patch(path, pairs):
    p = pathlib.Path(path); s = p.read_text()
    for old, new in pairs:
        assert s.count(old) == 1, (path, old[:50])
        s = s.replace(old, new)
    p.write_text(s)

patch("docs/README.md", [(
    "- [Drone Mesh Mapper](apps/drone-mesh-mapper/README.md)\n",
    "- [Drone Mesh Mapper](apps/drone-mesh-mapper/README.md)\n- [Cypher AirTag](apps/cypher-airtag/README.md)\n")])

patch("docs/APP_CATALOG.md", [(
    "| `drone-mesh-mapper` | `drone-mesh-mapper.bin` | `cardputer_adv` | `/drone/` | Open the Launcher page, then press BtnA, `Enter`, or `Space`. |\n",
    "| `drone-mesh-mapper` | `drone-mesh-mapper.bin` | `cardputer_adv` | `/drone/` | Open the Launcher page, then press BtnA, `Enter`, or `Space`. |\n"
    "| [Cypher AirTag](apps/cypher-airtag/README.md) | `cypher-airtag` | `cypher-airtag.bin` | `cardputer-adv` | `/cypher-airtag/` | Choose Return to Cypher OS on the Settings page, press backtick on the Radar page and confirm with `Enter`, or type `return` over serial. |\n")])

patch("README.md", [
    ("| **[Drone Mesh Mapper][drone-mesh-mapper-repo]** | [Cardputer ADV][cardputer-affiliate] passive Remote ID scanner with SD field logs. |\n",
     "| **[Drone Mesh Mapper][drone-mesh-mapper-repo]** | [Cardputer ADV][cardputer-affiliate] passive Remote ID scanner with SD field logs. |\n"
     "| **[Cypher AirTag][cypher-airtag-repo]** | [Cardputer ADV][cardputer-affiliate] passive Apple Find My / AirTag detector with following alerts and locate beeps. |\n"),
    ("[WireTap-32][wiretap-32-repo], [Drone Mesh Mapper][drone-mesh-mapper-repo],\n",
     "[WireTap-32][wiretap-32-repo], [Drone Mesh Mapper][drone-mesh-mapper-repo],\n[Cypher AirTag][cypher-airtag-repo],\n"),
    ("- Drone Mesh Mapper: open the `Launcher` page, then press BtnA, `Enter`, or\n  `Space`.\n",
     "- Drone Mesh Mapper: open the `Launcher` page, then press BtnA, `Enter`, or\n  `Space`.\n"
     "- Cypher AirTag: choose `Return to Cypher OS` on the Settings page, press\n  backtick on the Radar page and confirm, or type `return` over serial.\n"),
    ("CYPHER_OS_DRONE_MESH_MAPPER_DIR=/path/to/drone-mesh-mapper ./tools/build-apps.sh\n",
     "CYPHER_OS_DRONE_MESH_MAPPER_DIR=/path/to/drone-mesh-mapper ./tools/build-apps.sh\nCYPHER_OS_CYPHER_AIRTAG_DIR=/path/to/cypher-airtag ./tools/build-apps.sh\n"),
    ("[drone-mesh-mapper-repo]: https://github.com/dkyazzentwatwa/drone-mesh-mapper\n",
     "[drone-mesh-mapper-repo]: https://github.com/dkyazzentwatwa/drone-mesh-mapper\n[cypher-airtag-repo]: https://github.com/dkyazzentwatwa/cypher-airtag\n"),
])

patch("docs/BUILDING_AND_PACKAGING.md", [(
    "CYPHER_OS_DRONE_MESH_MAPPER_DIR=/path/to/drone-mesh-mapper ./tools/build-apps.sh\n",
    "CYPHER_OS_DRONE_MESH_MAPPER_DIR=/path/to/drone-mesh-mapper ./tools/build-apps.sh\nCYPHER_OS_CYPHER_AIRTAG_DIR=/path/to/cypher-airtag ./tools/build-apps.sh\n")])

patch("AGENTS.md", [(
    "`cypher-chat`, `cypher-drive`, `cypher-desk`, `esp32-pokedex`, `flock-you`,\nand `WireTap-32` are treated",
    "`cypher-chat`, `cypher-drive`, `cypher-desk`, `esp32-pokedex`, `flock-you`,\n`cypher-airtag`, and `WireTap-32` are treated")])
print("docs patched")
PY
```
Expected: `docs patched`.

- [ ] **Step 6: Validate the catalog and prove the integration build path, then restore `dist/`**

```bash
cd /Users/cypher/Documents/GitHub/cypher-puter-os && python3 tools/validate-catalog.py config/apps.json && \
  ./tools/build-apps.sh --app cypher-airtag; status=$?; git checkout -- dist; git status --short dist | head -3; exit_code=$status; echo "build-apps exit=${exit_code}"
```
Expected: `[catalog] ok`, `[apps] building cypher-airtag`, `[apps] packaged cypher-airtag.bin`, `[catalog] ok`, then `build-apps exit=0` and no lines from `git status --short dist` (the committed bundle is intact). Every other app reports `skipped` in the transient report, which is expected on a machine without the sibling repos.

- [ ] **Step 7: Commit the integration**

```bash
cd /Users/cypher/Documents/GitHub/cypher-puter-os && git add config/apps.json tools/build-apps.sh tools/build-report.py tools/package-sd.sh docs/apps/cypher-airtag/README.md docs/README.md docs/APP_CATALOG.md docs/BUILDING_AND_PACKAGING.md README.md AGENTS.md && \
git commit -q -m "feat: add Cypher AirTag detector to the app catalog

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" && git log --oneline -1
```

---

### Task 12: `tools/flash-app-slot.sh` dev helper + on-device verification

**Files:**
- Create: `$OS/tools/flash-app-slot.sh`
- Modify: `$OS/docs/BUILDING_AND_PACKAGING.md` (new subsection before `## Build App Binaries`)

- [ ] **Step 1: Write `tools/flash-app-slot.sh`**

```bash
#!/usr/bin/env bash
# Dev-loop helper: write an app .bin into the Cypher OS app slot (app1 @ 0x170000) over USB,
# then ask the resident launcher to boot it. The launcher in app0 is never rewritten.
set -euo pipefail

BIN="${1:-}"
PORT="${2:-}"
APP_SLOT_OFFSET="0x170000"
APP_SLOT_SIZE=$((0x4F0000))  # app1 in partitions.csv

usage() {
  cat <<'USAGE'
Usage: ./tools/flash-app-slot.sh <app.bin> [/dev/cu.usbmodemXXXX]

Writes a sketch app .bin (not a merged image) into the app1 slot and sends
"launch" to the Cypher OS launcher over serial so the device reboots into it.
Return to the launcher from the app as usual; the launcher shows the slot as
"Unknown app" because no catalog install recorded a name.
USAGE
}

detect_port() {
  ls /dev/cu.usbmodem* 2>/dev/null | head -n 1 || true
}

find_esptool() {
  local candidate
  for candidate in "${HOME}"/Library/Arduino15/packages/*/tools/esptool_py/*/esptool; do
    if [[ -x "${candidate}" ]]; then
      echo "${candidate}"
      return 0
    fi
  done
  if command -v esptool.py >/dev/null 2>&1; then
    echo "esptool.py"
    return 0
  fi
  return 1
}

if [[ -z "${BIN}" || "${BIN}" == "-h" || "${BIN}" == "--help" ]]; then
  usage
  exit 2
fi
if [[ ! -f "${BIN}" ]]; then
  echo "[slot] missing binary: ${BIN}" >&2
  exit 1
fi

size="$(stat -f %z "${BIN}")"
if (( size > APP_SLOT_SIZE )); then
  echo "[slot] ${BIN} is ${size} bytes; the app1 slot holds ${APP_SLOT_SIZE}" >&2
  exit 1
fi
magic="$(head -c 1 "${BIN}" | xxd -p)"
if [[ "${magic}" != "e9" ]]; then
  echo "[slot] ${BIN} does not start with the ESP app image magic 0xE9; use a sketch .bin, not a merged image" >&2
  exit 1
fi

ESPTOOL="$(find_esptool)" || {
  echo "[slot] esptool not found; install the esp32 core with arduino-cli first" >&2
  exit 1
}
if [[ -z "${PORT}" ]]; then
  PORT="$(detect_port)"
fi
if [[ -z "${PORT}" ]]; then
  echo "[slot] no /dev/cu.usbmodem* port found; connect the Cardputer ADV" >&2
  exit 1
fi

echo "[slot] writing ${BIN} (${size} bytes) to ${APP_SLOT_OFFSET} via ${PORT}"
"${ESPTOOL}" --chip esp32s3 --port "${PORT}" --baud 921600 --before default_reset --after hard_reset \
  write_flash "${APP_SLOT_OFFSET}" "${BIN}"

echo "[slot] waiting for the launcher to boot"
for _ in $(seq 1 20); do
  PORT_NOW="$(detect_port)"
  if [[ -n "${PORT_NOW}" ]]; then
    PORT="${PORT_NOW}"
    break
  fi
  sleep 0.5
done
sleep 3
stty -f "${PORT}" 115200 raw -echo
printf 'launch\n' > "${PORT}"
echo "[slot] sent launch; the Cardputer should now reboot into the app"
```

- [ ] **Step 2: Document it in `docs/BUILDING_AND_PACKAGING.md`**

Insert this block immediately before the line `## Build App Binaries`:

````markdown
## Flash An App Into The App Slot

For quick iteration on a single app, skip the SD card and write the app `.bin`
straight into the `app1` slot. The launcher in `app0` is untouched, and the
script asks it to boot the new binary over serial:

```bash
./tools/flash-app-slot.sh ../cypher-airtag/build/device/cypher-airtag.ino.bin
```

The launcher lists the slot as "Unknown app" because no catalog install
recorded a name. Returning to Cypher OS from the app works as usual. Installing
any app from the SD catalog overwrites the slot again.

````

- [ ] **Step 3: Make it executable and commit**

```bash
cd /Users/cypher/Documents/GitHub/cypher-puter-os && chmod +x tools/flash-app-slot.sh && bash -n tools/flash-app-slot.sh && \
git add tools/flash-app-slot.sh docs/BUILDING_AND_PACKAGING.md && \
git commit -q -m "tools: add flash-app-slot dev helper

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" && git log --oneline -1
```

- [ ] **Step 4: Flash the app into the slot and capture 30 s of serial output**

```bash
cd /Users/cypher/Documents/GitHub/cypher-puter-os && ./tools/flash-app-slot.sh ../cypher-airtag/build/device/cypher-airtag.ino.bin
```
Expected: esptool writes ~1.2 MB, `Hash of data verified`, then `[slot] sent launch`.

```bash
PORT=$(ls /dev/cu.usbmodem* | head -n 1); LOG=/private/tmp/claude-501/-Users-cypher-Documents-GitHub-cypher-puter-os/7a653f70-8c52-4ec7-b377-980762c22452/scratchpad/airtag-serial.log; \
stty -f "$PORT" 115200 raw -echo; (cat "$PORT" > "$LOG" &); sleep 30; pkill -f "cat $PORT" || true; cat "$LOG" | head -40
```
Expected: a `{"ev":"boot",...,"fw":"0.1.0","sd":"mounted"...}` line (or `"sd":"missing"` if no card), followed by `seen`/`update` lines for any Find My devices in range (a nearby iPhone, AirPods, or AirTag).

- [ ] **Step 5: Exercise the serial console and return path**

```bash
PORT=$(ls /dev/cu.usbmodem* | head -n 1); LOG=/private/tmp/claude-501/-Users-cypher-Documents-GitHub-cypher-puter-os/7a653f70-8c52-4ec7-b377-980762c22452/scratchpad/airtag-serial2.log; \
stty -f "$PORT" 115200 raw -echo; (cat "$PORT" > "$LOG" &); sleep 1; printf 'status\n' > "$PORT"; sleep 2; printf 'return\n' > "$PORT"; sleep 8; pkill -f "cat $PORT" || true; cat "$LOG"
```
Expected: a `{"ev":"status",...}` line, then `Cypher OS boot` and the launcher's `sd=... installed=... bootToApp=false` status line, proving the one-shot return landed in the launcher.

- [ ] **Step 6: Hands-on checklist (needs a person with an AirTag and its paired iPhone)**

Run through items 2–7, 9 and 10 of the spec's §9.3 on the device, and confirm `/cypher-airtag/logs/findmy.jsonl` on the card contains `boot`, `seen`, `update`, `mode`, `alert`, `mute`, and `lost` lines. Record anything that fails as a bug to fix before Task 13.

---

### Task 13: App README, final review, and handoff

**Files:**
- Modify: `$APP/README.md`

- [ ] **Step 1: Write the full `README.md` in the sibling repo**

```markdown
# Cypher AirTag

Passive Apple Find My / AirTag detector for the M5Stack Cardputer ADV, packaged
as a [Cypher OS](https://github.com/dkyazzentwatwa/cypher-puter-os) SD catalog
app. It lists nearby Find My advertisers, flags separated tags that keep
travelling with you, helps you locate one by sound, and logs everything as JSON
lines.

## Build

Arduino CLI only. The `cardputer-adv` profile in `sketch.yaml` pins the
`m5stack:esp32` core, M5Cardputer/M5Unified/M5GFX, and NimBLE-Arduino.

```bash
tools/run-host-tests.sh   # unit tests for src/core on your Mac (clang++)
tools/build.sh            # arduino-cli compile, prints the .bin size
```

`tools/build.sh` picks up `CypherPuterReturn.h` from a sibling
`cypher-puter-os` checkout (override with `CYPHER_OS_RETURN_LIB`). Without it,
"Return to Cypher OS" falls back to a plain restart.

From the Cypher OS repo, `./tools/build-apps.sh --app cypher-airtag` builds the
catalog binary and `./tools/flash-app-slot.sh build/device/cypher-airtag.ino.bin`
flashes a dev build into the launcher's app slot.

## Layout

- `src/core/` — pure C++17, no Arduino headers: advert parser, tracker
  registry, following-alert rule, formatters. Covered by `test/host/`.
- `src/device/` — Arduino/M5/NimBLE glue: BLE scan, UI, input, event log,
  settings, sound, and the `App` state machine.

## Controls

Same key map as the Cypher OS launcher.

| Action | Keys |
| --- | --- |
| Move selection | `;` `,` `w` `k` up, `.` `/` `s` `j` down |
| Switch page (Radar, Alerts, Settings) | `a` `h` left, `d` `l` right |
| Open detail / change a setting | `Enter` or BtnA |
| Back / dismiss | `Del`, `Tab`, backtick, `q` |
| Locate beeps (detail page) | `Space` |
| Mute a tag's alerts | `m` |

Backtick on the Radar page (then `Enter`) or Settings → Return to Cypher OS
reboots into the launcher. Over USB serial: `return`, `launcher`, `status`,
`help`.

## Detection

- Apple Offline Finding adverts carry company ID `0x004C` and type `0x12`.
  Length `0x02` is **nearby** (owner seen within ~15 min); length `0x19` is
  **separated** and carries 22 bytes of the rotating public key.
- Class (`AT` AirTag, `FM` Find My accessory, `AP` AirPods, `AD` other Apple
  device) and battery come from the status byte the way AirGuard reads them.
  Apple does not document these bits; treat them as best-effort.
- Following alert: a separated tag continuously present (no gap over 2 min)
  for the threshold (5/10/15/30/60 min, default 10) alerts once per presence
  window. Nearby tags never alert.
- Identity is the advertising MAC, which rotates with the key: roughly every
  15 min in nearby mode, daily in separated mode.

## Log Format

`/cypher-airtag/logs/findmy.jsonl` (rotates once at 4 MB) and USB serial at
115200 baud, one JSON object per line:

| `ev` | Fields |
| --- | --- |
| `boot` | `fw`, `sd`, `thresh_min` |
| `seen` | `mac`, `cls`, `mode`, `rssi`, `batt`, `status`, `key` (56 hex, separated only) |
| `update` | `mac`, `mode`, `rssi_ema`, `advs`, `presence_s` — every 60 s per present tag |
| `mode` | `mac`, `from`, `to` |
| `alert` | `mac`, `cls`, `presence_s`, `rssi` |
| `mute` | `mac` |
| `lost` | `mac`, `presence_s`, `advs` |
| `sd` | `state` |

Every line also has `t` (ms since boot) and `session` (boot counter).

## On-Device Checklist

1. Boot: footer spinner turns; serial prints the `boot` line.
2. AirTag near its paired iPhone: row shows `AT` and `near`.
3. iPhone in airplane mode for ~15 min: row flips to `sep`; `mode` logged.
4. Threshold 5 min: overlay + three chirps once; `alert` logged; ALERTS lists it.
5. `m` on the tag: `mute` logged; no further alert for that MAC.
6. Locate (`Space` on detail): beeps speed up as the tag gets closer.
7. Remove the tag for over 5 min: `lost` logged, row disappears.
8. `findmy.jsonl` holds the lines above with increasing `t`, constant `session`.
9. Settings survive a power cycle.
10. Return to Cypher OS lands in the launcher's "Returned To Launcher" message.

## Notes

- No GPS: "following" is continuous presence in time, not across places.
- A powered-off iPhone, iPad, Mac, or AirPods case also advertises Offline
  Finding and shows up as `AD`/`AP`.
- Passive listening only. Use where such monitoring is legal and authorized.
```

- [ ] **Step 2: Run everything one last time**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && tools/run-host-tests.sh && tools/build.sh && git status --short
```
Expected: `36 tests, 0 failures`, `[build] ok ...`, and only `README.md` modified.

- [ ] **Step 3: Commit**

```bash
cd /Users/cypher/Documents/GitHub/cypher-airtag && git add -A && \
git commit -q -m "docs: document build, controls, detection, and log format

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" && git log --oneline -1
```

- [ ] **Step 4: Confirm both repos are clean and summarise**

```bash
cd /Users/cypher/Documents/GitHub/cypher-puter-os && git status --short --branch && git log --oneline main..HEAD && \
cd /Users/cypher/Documents/GitHub/cypher-airtag && git log --oneline
```
Expected: the `feat/cypher-airtag` branch with the spec, plan, integration, and tool commits; the sibling repo with one commit per task. Report the binary size, the host test count, what was verified on hardware, and that publishing `cypher-airtag` to GitHub and refreshing `dist/` on the next full release build remain the user's calls.
