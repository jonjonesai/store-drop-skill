#!/usr/bin/env python3
"""Read and update dotenv files without sourcing them."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from store_drop.config import ConfigError, load_dotenv  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("validate", "get", "set"))
    parser.add_argument("path")
    parser.add_argument("key", nargs="?")
    parser.add_argument("value", nargs="?")
    args = parser.parse_args()
    path = Path(args.path)
    try:
        values = load_dotenv(path)
        if args.command == "validate":
            return 0
        if not args.key:
            parser.error("get/set requires a key")
        if args.command == "get":
            print(values.get(args.key, ""), end="")
            return 0
        values[args.key] = args.value or ""
        content = "".join(f"{key}={json.dumps(value, ensure_ascii=False)}\n" for key, value in values.items())
        path.write_text(content, encoding="utf-8")
        return 0
    except (ConfigError, OSError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
