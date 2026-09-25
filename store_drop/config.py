"""Strict dotenv parsing without executing configuration as shell code."""

from __future__ import annotations

import re
from pathlib import Path


class ConfigError(ValueError):
    """Raised when a dotenv file is malformed."""


_KEY = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def _unescape_double(value: str, line_number: int) -> str:
    out: list[str] = []
    i = 0
    escapes = {"n": "\n", "r": "\r", "t": "\t", "\\": "\\", '"': '"'}
    while i < len(value):
        if value[i] != "\\":
            out.append(value[i])
            i += 1
            continue
        i += 1
        if i >= len(value):
            raise ConfigError(f"line {line_number}: trailing escape in quoted value")
        out.append(escapes.get(value[i], "\\" + value[i]))
        i += 1
    return "".join(out)


def _parse_value(raw: str, line_number: int) -> str:
    raw = raw.strip()
    if not raw:
        return ""
    quote = raw[0]
    if quote in ("'", '"'):
        escaped = False
        end = None
        for i in range(1, len(raw)):
            char = raw[i]
            if quote == '"' and char == "\\" and not escaped:
                escaped = True
                continue
            if char == quote and not escaped:
                end = i
                break
            escaped = False
        if end is None:
            raise ConfigError(f"line {line_number}: unterminated quoted value")
        tail = raw[end + 1 :].strip()
        if tail and not tail.startswith("#"):
            raise ConfigError(f"line {line_number}: unexpected text after quoted value")
        value = raw[1:end]
        return _unescape_double(value, line_number) if quote == '"' else value

    # In unquoted values, a hash begins a comment only when preceded by
    # whitespace. This preserves URLs, colors, and application passwords.
    match = re.search(r"\s+#", raw)
    if match:
        raw = raw[: match.start()]
    return raw.rstrip()


def parse_dotenv_text(text: str) -> dict[str, str]:
    values: dict[str, str] = {}
    for line_number, original in enumerate(text.splitlines(), 1):
        line = original.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[7:].lstrip()
        if "=" not in line:
            raise ConfigError(f"line {line_number}: expected KEY=VALUE")
        key, raw = line.split("=", 1)
        key = key.strip()
        if not _KEY.fullmatch(key):
            raise ConfigError(f"line {line_number}: invalid key {key!r}")
        values[key] = _parse_value(raw, line_number)
    return values


def load_dotenv(path: str | Path) -> dict[str, str]:
    return parse_dotenv_text(Path(path).read_text(encoding="utf-8"))


def redact(value: str | None) -> str:
    return "<set>" if value else "<missing>"
