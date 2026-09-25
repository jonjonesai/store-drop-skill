#!/usr/bin/env python3
"""Select an AI adapter and run Store Drop without leaking ambient environment."""

from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from store_drop.config import ConfigError, load_dotenv  # noqa: E402
from store_drop.provider import (  # noqa: E402
    ProviderConfig,
    describe,
    require_archon_version,
    run_archon,
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--provider", choices=("codex", "claude", "pi"))
    parser.add_argument("--model")
    parser.add_argument("--archon-command")
    parser.add_argument("--env-file", default=str(ROOT / ".env"))
    parser.add_argument("--dry-run", action="store_true", help="show selection and requirements only")
    parser.add_argument("--check-auth", action="store_true", help="verify the selected provider login only")
    parser.add_argument(
        "--preflight",
        action="store_true",
        help="verify provider login, adapter, and Archon before site access",
    )
    parser.add_argument("--archon-dry-run", action="store_true", help="validate DAG control flow without providers or site writes")
    args = parser.parse_args()
    try:
        dotenv = load_dotenv(args.env_file) if Path(args.env_file).is_file() else {}
        selection_env = {**os.environ, **dotenv}
        config = ProviderConfig.resolve(selection_env, args.provider, args.model, args.archon_command)
        if args.check_auth:
            authenticated, message = config.auth_status({**dotenv, **os.environ})
            if not authenticated:
                raise ConfigError(message)
            print(f"authentication: ready ({message})")
            return 0
        if args.preflight:
            preflight_env = {**dotenv, **os.environ}
            authenticated, message = config.auth_status(preflight_env)
            if not authenticated:
                raise ConfigError(message)
            config.require_provider_executable(preflight_env)
            archon = shutil.which(config.command, path=preflight_env.get("PATH"))
            if not archon:
                raise ConfigError(f"Archon command not found: {config.command!r}")
            require_archon_version(archon)
            print(f"runtime preflight: ready ({config.provider}, {config.model})")
            return 0
        print(describe(config, {**dotenv, **os.environ}, dotenv))
        if args.dry_run:
            return 0
        extra = ("--dry-run", "--default-stubs") if args.archon_dry_run else ()
        return run_archon(ROOT, config, dotenv, extra_args=extra, check_auth=not args.archon_dry_run)
    except ConfigError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
