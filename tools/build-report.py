#!/usr/bin/env python3
"""Generate release manifests and BUILD_REPORT.md from build-apps.sh state."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


STATUS_ENV = {
    "cardputer-games": ("CARDPUTER_GAMES_STATUS", "CARDPUTER_GAMES_ROOT"),
    "cardputer-mpc": ("CARDPUTER_MPC_STATUS", "CARDPUTER_MPC_ROOT"),
    "cardputer-tarot": ("CARDPUTER_TAROT_STATUS", "CARDPUTER_TAROT_ROOT"),
    "cypher-pn532": ("CYPHER_PN532_STATUS", "CYPHER_PN532_ROOT"),
    "cypher-chat": ("CYPHER_CHAT_STATUS", "CYPHER_CHAT_ROOT"),
    "cypher-drive": ("CYPHER_DRIVE_STATUS", "CYPHER_DRIVE_ROOT"),
    "esp32-bt-hid": ("ESP32_BT_HID_STATUS", "ESP32_BT_HID_ROOT"),
    "esp32-pokedex": ("ESP32_POKEDEX_STATUS", "ESP32_POKEDEX_ROOT"),
    "cypher-desk": ("CYPHER_DESK_STATUS", "CYPHER_DESK_ROOT"),
    "flock-you": ("FLOCK_YOU_STATUS", "FLOCK_YOU_ROOT"),
    "wiretap-32-cardputer": ("WIRETAP_STATUS", "WIRETAP_ROOT"),
}
IMPORT_ENV = {
    "cardputer-game-os-games": ("GAME_OS_STATUS", "GAME_OS_ROOT"),
}


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return data


def git_commit(path: str) -> str:
    if not path or not Path(path).exists():
        return ""
    try:
        return subprocess.check_output(
            ["git", "-C", path, "rev-parse", "--short", "HEAD"],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except (OSError, subprocess.CalledProcessError):
        return ""


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def app_manifest_entry(app: dict[str, Any], binary_path: Path, status: str, source_path: str) -> dict[str, Any]:
    return {
        "name": app["name"],
        "slug": app["slug"],
        "binary": app["binary"] if status == "ready" else "",
        "source_path": source_path,
        "repo_url": app["repo_url"],
        "version": os.environ.get("CYPHER_OS_RELEASE_VERSION", "local"),
        "status": status,
        "notes": app["notes"],
        "return_to_launcher": app["return_to_launcher"],
        "sd_paths": app.get("sd_paths", []),
        "binary_size": binary_path.stat().st_size if status == "ready" and binary_path.exists() else 0,
        "sha256": sha256(binary_path) if status == "ready" and binary_path.exists() else "",
        "source_commit": git_commit(source_path),
    }


def load_game_apps(game_manifest: Path, import_entry: dict[str, Any], source_path: str) -> list[dict[str, Any]]:
    if not game_manifest.exists():
        return []
    with game_manifest.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    games = data if isinstance(data, list) else data.get("games", [])
    if not isinstance(games, list):
        return []

    entries: list[dict[str, Any]] = []
    for game in games:
        if not isinstance(game, dict):
            continue
        slug = game.get("slug", "")
        binary = game.get("binary", "")
        if not slug or not binary:
            continue
        entries.append(
            {
                "name": game.get("name", "Game OS App"),
                "slug": slug,
                "binary": binary,
                "source_path": game.get("source_path", source_path),
                "repo_url": import_entry["repo_url"],
                "version": game.get("version", os.environ.get("CYPHER_OS_RELEASE_VERSION", "local")),
                "status": game.get("status", "ready"),
                "notes": "Cardputer Game OS import. " + game.get("notes", ""),
                "return_to_launcher": import_entry["return_to_launcher"],
                "sd_paths": game.get("sd_paths", import_entry.get("sd_paths", [])),
                "binary_size": 0,
                "sha256": "",
                "source_commit": git_commit(source_path),
            }
        )
    return entries


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")


def write_report(
    path: Path,
    manifest: dict[str, Any],
    catalog_apps: list[dict[str, Any]],
    imports: list[dict[str, Any]],
    selected: str,
) -> None:
    ready = [app for app in manifest["apps"] if app.get("status") == "ready"]
    failed = [app for app in catalog_apps if app["_status"] == "build_failed"]
    skipped = [app for app in catalog_apps if app["_status"] == "skipped"]
    missing = [app for app in catalog_apps if app["_status"] == "build_missing"]

    lines = [
        "# Cypher OS Build Report",
        "",
        f"- Generated: `{manifest['generated_at']}`",
        f"- Release version: `{manifest['release_version']}`",
        f"- Requested app: `{selected or 'all'}`",
        f"- Ready app entries: `{len(ready)}`",
        f"- Failed primary apps: `{len(failed)}`",
        f"- Skipped primary apps: `{len(skipped)}`",
        f"- Missing primary apps: `{len(missing)}`",
        "",
        "## Ready Apps",
        "",
        "| App | Slug | Binary | Size | Source Commit |",
        "| --- | --- | --- | ---: | --- |",
    ]
    for app in ready:
        lines.append(
            f"| {app['name']} | `{app['slug']}` | `{app['binary']}` | {app.get('binary_size', 0)} | `{app.get('source_commit', '') or 'n/a'}` |"
        )

    lines.extend(["", "## Not Ready", "", "| App | Slug | Status | Source |", "| --- | --- | --- | --- |"])
    for app in failed + missing + skipped:
        lines.append(f"| {app['name']} | `{app['slug']}` | `{app['_status']}` | `{app['_source_path']}` |")
    if not (failed or missing or skipped):
        lines.append("| None | `-` | `-` | `-` |")

    lines.extend(["", "## Imports", "", "| Import | Status | Source |", "| --- | --- | --- |"])
    for item in imports:
        lines.append(f"| {item['name']} | `{item['_status']}` | `{item['_source_path']}` |")

    lines.extend(
        [
            "",
            "## Commands",
            "",
            "- Launcher: `./tools/build-launcher.sh` or `arduino-cli compile --profile adv .`",
            "- Apps: `./tools/build-apps.sh` or `./tools/build-apps.sh --app <slug>`",
            "- SD package: `./tools/package-sd.sh`",
            "",
            "## SD Notes",
            "",
            "- The release SD zip contains the app manifest and built app binaries under `/cypher-puter/apps/`.",
            "- Cardputer MPC runtime assets are packaged under `/cardputer-mpc/` when present.",
            "- Cypher Drive / ESP32 BT HID payload assets are packaged under `/cypher-drive/` when present.",
            "- ESP32 Pokedex ships as an app binary here; full sprite/audio/data content still belongs at `/pokemon`, `/audio`, and `/config`.",
        ]
    )

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, required=True)
    parser.add_argument("--dist", type=Path, required=True)
    parser.add_argument("--game-manifest", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--selected", default="")
    args = parser.parse_args()

    catalog = load_json(args.catalog)
    generated_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    release_version = os.environ.get("CYPHER_OS_RELEASE_VERSION", "local")

    manifest_apps: list[dict[str, Any]] = []
    report_apps: list[dict[str, Any]] = []
    for app in catalog.get("apps", []):
        slug = app["slug"]
        status_var, path_var = STATUS_ENV[slug]
        status = os.environ.get(status_var, "build_missing")
        source_path = os.environ.get(path_var, app["local_default_path"])
        binary_path = args.dist / app["binary"]
        report_app = dict(app)
        report_app["_status"] = status
        report_app["_source_path"] = source_path
        report_apps.append(report_app)
        if status == "ready" and binary_path.exists():
            manifest_apps.append(app_manifest_entry(app, binary_path, status, source_path))

    report_imports: list[dict[str, Any]] = []
    for item in catalog.get("imports", []):
        slug = item["slug"]
        status_var, path_var = IMPORT_ENV[slug]
        status = os.environ.get(status_var, "build_missing")
        source_path = os.environ.get(path_var, item["local_default_path"])
        report_item = dict(item)
        report_item["_status"] = status
        report_item["_source_path"] = source_path
        report_imports.append(report_item)
        if status == "ready":
            game_apps = load_game_apps(args.game_manifest, item, source_path)
            for game_app in game_apps:
                binary_path = args.dist / game_app["binary"]
                if binary_path.exists():
                    game_app["binary_size"] = binary_path.stat().st_size
                    game_app["sha256"] = sha256(binary_path)
                    manifest_apps.append(game_app)

    manifest = {
        "generated_by": "tools/build-apps.sh",
        "generated_at": generated_at,
        "release_version": release_version,
        "catalog_version": catalog.get("catalog_version", 1),
        "target_hardware": catalog.get("target_hardware", "M5Stack Cardputer ADV"),
        "apps": manifest_apps,
    }
    write_json(args.dist / "apps.json", manifest)
    write_report(args.report, manifest, report_apps, report_imports, args.selected)
    print(f"[apps] manifest: {args.dist / 'apps.json'}")
    print(f"[apps] report: {args.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
