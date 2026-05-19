#!/usr/bin/env python3
"""Validate Cypher OS source and generated app catalogs."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


REQUIRED_APP_FIELDS = {
    "name",
    "slug",
    "binary",
    "repo_url",
    "local_default_path",
    "build_profile",
    "sd_paths",
    "return_to_launcher",
    "public_release",
    "status",
    "notes",
}
REQUIRED_IMPORT_FIELDS = REQUIRED_APP_FIELDS - {"binary"}
BIN_RE = re.compile(r"^[a-z0-9][a-z0-9._-]*\.bin$")
SLUG_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
FORBIDDEN = ("starbeam_v2", "starbeam-v2")


def load_json(path: Path) -> object:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def validate_binary(errors: list[str], slug: str, binary: str) -> None:
    if not binary:
        fail(errors, f"{slug}: binary is required")
        return
    if not BIN_RE.match(binary):
        fail(errors, f"{slug}: invalid binary filename {binary!r}")
    lowered = binary.lower()
    if lowered.endswith((".merged.bin", ".bootloader.bin", ".partitions.bin")):
        fail(errors, f"{slug}: binary must be a sketch app .bin, not {binary}")


def validate_source_catalog(path: Path, repo_root: Path, errors: list[str]) -> None:
    data = load_json(path)
    if not isinstance(data, dict):
        fail(errors, "source catalog must be a JSON object")
        return

    all_text = json.dumps(data, sort_keys=True).lower()
    for forbidden in FORBIDDEN:
        if forbidden in all_text:
            fail(errors, f"source catalog contains forbidden entry {forbidden}")

    apps = data.get("apps")
    imports = data.get("imports", [])
    if not isinstance(apps, list) or not apps:
        fail(errors, "source catalog must include a non-empty apps array")
        return
    if not isinstance(imports, list):
        fail(errors, "imports must be an array when present")
        return

    seen: set[str] = set()
    for section_name, entries, required in (
        ("apps", apps, REQUIRED_APP_FIELDS),
        ("imports", imports, REQUIRED_IMPORT_FIELDS),
    ):
        for idx, entry in enumerate(entries):
            if not isinstance(entry, dict):
                fail(errors, f"{section_name}[{idx}] must be an object")
                continue

            missing = sorted(required - set(entry))
            slug = str(entry.get("slug", f"{section_name}[{idx}]"))
            if missing:
                fail(errors, f"{slug}: missing fields: {', '.join(missing)}")
                continue

            if not SLUG_RE.match(slug):
                fail(errors, f"{slug}: slug must use lowercase letters, digits, and hyphens")
            if slug in seen:
                fail(errors, f"{slug}: duplicate slug")
            seen.add(slug)

            if any(forbidden in slug.lower() for forbidden in FORBIDDEN):
                fail(errors, f"{slug}: forbidden app slug")

            if section_name == "apps":
                validate_binary(errors, slug, str(entry.get("binary", "")))
                doc_path = repo_root / "docs" / "apps" / slug / "README.md"
                if not doc_path.exists():
                    fail(errors, f"{slug}: missing docs page {doc_path.relative_to(repo_root)}")

            repo_url = str(entry.get("repo_url", ""))
            if not repo_url.startswith("https://github.com/"):
                fail(errors, f"{slug}: repo_url must be a public GitHub HTTPS URL")

            if not isinstance(entry.get("sd_paths"), list):
                fail(errors, f"{slug}: sd_paths must be an array")
            if not isinstance(entry.get("public_release"), bool):
                fail(errors, f"{slug}: public_release must be a boolean")


def validate_generated_manifest(path: Path, dist_dir: Path | None, errors: list[str]) -> None:
    data = load_json(path)
    if not isinstance(data, dict):
        fail(errors, "generated manifest must be a JSON object")
        return

    for key in ("generated_by", "generated_at", "catalog_version", "apps"):
        if key not in data:
            fail(errors, f"generated manifest missing {key}")

    apps = data.get("apps")
    if not isinstance(apps, list):
        fail(errors, "generated manifest apps must be an array")
        return

    seen: set[str] = set()
    for idx, app in enumerate(apps):
        if not isinstance(app, dict):
            fail(errors, f"generated apps[{idx}] must be an object")
            continue
        slug = str(app.get("slug", ""))
        binary = str(app.get("binary", ""))
        status = str(app.get("status", ""))
        if not slug:
            fail(errors, f"generated apps[{idx}] missing slug")
            continue
        if slug in seen:
            fail(errors, f"{slug}: duplicate generated slug")
        seen.add(slug)
        if any(forbidden in slug.lower() for forbidden in FORBIDDEN):
            fail(errors, f"{slug}: forbidden generated app")
        if status == "ready":
            validate_binary(errors, slug, binary)
            if dist_dir is not None and binary and not (dist_dir / binary).exists():
                fail(errors, f"{slug}: generated manifest references missing binary {binary}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("catalog", type=Path, help="source config/apps.json")
    parser.add_argument("--manifest", type=Path, help="generated apps.json to validate")
    parser.add_argument("--dist", type=Path, help="directory containing generated app binaries")
    args = parser.parse_args()

    repo_root = args.catalog.resolve().parents[1]
    errors: list[str] = []
    validate_source_catalog(args.catalog, repo_root, errors)
    if args.manifest:
        validate_generated_manifest(args.manifest, args.dist, errors)

    if errors:
        for error in errors:
            print(f"[catalog] ERROR: {error}", file=sys.stderr)
        return 1
    print("[catalog] ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
