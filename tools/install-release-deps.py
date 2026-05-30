#!/usr/bin/env python3
"""Install Arduino CLI platforms and libraries needed for public release builds."""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]

PROFILE_TARGETS = [
    (ROOT, "adv"),
    (ROOT.parent / "cardputer-games", "adv"),
    (ROOT.parent / "cardputer-mpc", "cardputer"),
    (ROOT.parent / "cardputer-tarot" / "CardputerTarot", "cardputer"),
    (ROOT.parent / "cypher-pn532" / "CardputerPN532", "adv"),
    (ROOT.parent / "ESP32_BT_HID", "cardputer"),
    (ROOT.parent / "esp32-pokedex", "cardputer"),
    (ROOT.parent / "cypher-desk", "adv"),
    (ROOT.parent / "drone-mesh-mapper" / "firmware" / "drone_mesh_mapper", "cardputer_adv"),
    (ROOT.parent / "cardputer-game-os", "adv"),
]

PLATFORM_URLS = {
    "m5stack:esp32": "https://static-cdn.m5stack.com/resource/arduino/package_m5stack_index.json",
    "esp32:esp32": "https://espressif.github.io/arduino-esp32/package_esp32_index.json",
}

EXTRA_PLATFORMS = {
    "m5stack:esp32": None,
    "esp32:esp32": None,
}

EXTRA_LIBRARIES = {
    "Adafruit BusIO": "1.17.4",
    "Adafruit GFX Library": "1.12.6",
    "Adafruit NeoPixel": "1.15.5",
    "Adafruit SSD1306": "2.5.16",
    "Adafruit ST7735 and ST7789 Library": "1.11.0",
    "Adafruit XCA9554": None,
    "Async TCP": "3.4.10",
    "ESP Async WebServer": "3.11.0",
    "GFX Library for Arduino": None,
    "HijelHID_BLEKeyboard": "0.5.0",
    "NimBLE-Arduino": "2.5.0",
    "TinyGPSPlus": None,
    "U8g2_for_Adafruit_GFX": "1.8.0",
    "XPowersLib": None,
}

GIT_LIBRARIES = [
    "https://github.com/Xk-w/Arduino_DriveBus.git",
]


def run(args: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    print("[deps] " + " ".join(args))
    return subprocess.run(args, check=check, text=True)


def parse_versioned(value: str) -> tuple[str, str | None]:
    value = value.strip()
    match = re.match(r"^(.*?)\s*\(([^)]+)\)\s*$", value)
    if match:
        return match.group(1).strip(), match.group(2).strip()
    if "@" in value:
        name, version = value.rsplit("@", 1)
        return name.strip(), version.strip()
    return value, None


def version_key(version: str | None) -> tuple[int, ...]:
    if not version:
        return ()
    return tuple(int(part) if part.isdigit() else 0 for part in re.split(r"[.-]", version))


def keep_highest(mapping: dict[str, str | None], name: str, version: str | None) -> None:
    current = mapping.get(name)
    if name not in mapping or version_key(version) > version_key(current):
        mapping[name] = version


def read_profile(sketch_dir: Path, profile_name: str) -> tuple[list[dict], list[str]]:
    sketch_yaml = sketch_dir / "sketch.yaml"
    if not sketch_yaml.exists():
        print(f"[deps] warning: missing {sketch_yaml}")
        return [], []

    data = yaml.safe_load(sketch_yaml.read_text(encoding="utf-8")) or {}
    profiles = data.get("profiles", {})
    profile = profiles.get(profile_name)
    if not profile:
        print(f"[deps] warning: missing profile {profile_name} in {sketch_yaml}")
        return [], []

    return profile.get("platforms", []), profile.get("libraries", [])


def install_platforms(platforms: dict[str, str | None], urls: set[str]) -> None:
    additional_urls = ",".join(sorted(urls))
    run(["arduino-cli", "core", "update-index", "--additional-urls", additional_urls])

    for platform, version in sorted(platforms.items()):
        spec = f"{platform}@{version}" if version else platform
        run(["arduino-cli", "core", "install", spec, "--additional-urls", additional_urls])


def install_libraries(libraries: dict[str, str | None]) -> None:
    for name, version in sorted(libraries.items()):
        spec = f"{name}@{version}" if version else name
        result = run(["arduino-cli", "lib", "install", spec], check=False)
        if result.returncode != 0:
            print(f"[deps] warning: could not install optional library {spec}")

    for url in GIT_LIBRARIES:
        run(["arduino-cli", "lib", "install", "--git-url", url])


def main() -> int:
    platforms = dict(EXTRA_PLATFORMS)
    libraries = dict(EXTRA_LIBRARIES)
    urls = set(PLATFORM_URLS.values())

    for sketch_dir, profile_name in PROFILE_TARGETS:
        profile_platforms, profile_libraries = read_profile(sketch_dir, profile_name)

        for platform_entry in profile_platforms:
            platform_name, platform_version = parse_versioned(platform_entry["platform"])
            keep_highest(platforms, platform_name, platform_version)
            if platform_entry.get("platform_index_url"):
                urls.add(platform_entry["platform_index_url"])
            elif platform_name in PLATFORM_URLS:
                urls.add(PLATFORM_URLS[platform_name])

        for library_entry in profile_libraries:
            library_name, library_version = parse_versioned(library_entry)
            keep_highest(libraries, library_name, library_version)

    install_platforms(platforms, urls)
    install_libraries(libraries)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
