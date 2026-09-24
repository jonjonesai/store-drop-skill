#!/usr/bin/env python3
"""Validate intake or build a certificate from verified read-back state."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from store_drop.safety import build_certificate, intake_errors  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--intake", required=True)
    parser.add_argument("--state")
    parser.add_argument("--output")
    args = parser.parse_args()
    intake = json.loads(Path(args.intake).read_text(encoding="utf-8"))
    errors = intake_errors(intake)
    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        return 1
    if not args.state:
        print("PASS: editorial intake schema validated")
        return 0
    state = json.loads(Path(args.state).read_text(encoding="utf-8"))
    certificate = build_certificate(state, intake)
    encoded = json.dumps(certificate, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        Path(args.output).write_text(encoded, encoding="utf-8")
    else:
        print(encoded, end="")
    print(
        "PASS: launch certified" if certificate["launch"]["certified"] else "REVIEW REQUIRED: launch is not certified",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
