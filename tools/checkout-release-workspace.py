#!/usr/bin/env python3
"""Clone public release app repos into the sibling layout used by build scripts."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "config" / "apps.json"


def run(args: list[str]) -> None:
    print("[workspace] " + " ".join(args))
    subprocess.run(args, check=True)


def load_targets() -> list[tuple[str, str, Path]]:
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    targets: list[tuple[str, str, Path]] = []

    for entry in [*data.get("apps", []), *data.get("imports", [])]:
        if not entry.get("public_release"):
            continue
        repo_url = entry.get("repo_url")
        local_default_path = entry.get("local_default_path")
        slug = entry.get("slug", repo_url)
        if not repo_url or not local_default_path:
            continue
        target = (ROOT / local_default_path).resolve()
        targets.append((slug, repo_url, target))

    return targets


def main() -> int:
    for slug, repo_url, target in load_targets():
        if target == ROOT:
            continue
        if target.exists():
            if (target / ".git").exists():
                print(f"[workspace] using existing {slug}: {target}")
                continue
            print(f"[workspace] refusing to overwrite non-git path: {target}", file=sys.stderr)
            return 1

        target.parent.mkdir(parents=True, exist_ok=True)
        run(["git", "clone", "--depth", "1", repo_url, str(target)])

    workspace_root = Path(os.environ.get("CYPHER_OS_WORKSPACE_ROOT", ROOT.parent)).resolve()
    print(f"[workspace] CYPHER_OS_WORKSPACE_ROOT={workspace_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
