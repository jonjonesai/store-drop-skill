"""Provider selection and Archon runner contract."""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping, Sequence

from .config import ConfigError, load_dotenv, redact


SUPPORTED_PROVIDERS = ("codex", "claude", "pi")
DEFAULT_MODELS = {
    "codex": "gpt-5.6-sol",
    "claude": "sonnet",
    "pi": "openai/gpt-5.6",
}
MIN_ARCHON_VERSION = (0, 10, 1)

# Nothing outside these names is inherited by Archon or its AI subprocesses.
COMMON_ENV = {
    "HOME",
    "PATH",
    "LANG",
    "LC_ALL",
    "TERM",
    "TMPDIR",
    "SSL_CERT_FILE",
    "SSL_CERT_DIR",
}
STORE_ENV = {
    "BRIDGE_URL",
    "BRIDGE_USER",
    "BRIDGE_PASS",
    "BRIDGE_SITE",
    "STORE_DROP_TOKEN",
    "MEGA_STORE_DROP_ENDPOINT",
}
PROVIDER_ENV = {
    "codex": {"CODEX_HOME", "CODEX_BIN_PATH", "OPENAI_API_KEY"},
    "claude": {"CLAUDE_BIN_PATH", "ANTHROPIC_API_KEY"},
    "pi": {
        "PI_CONFIG_DIR",
        "OPENAI_API_KEY",
        "ANTHROPIC_API_KEY",
        "GEMINI_API_KEY",
        "GROQ_API_KEY",
        "MISTRAL_API_KEY",
        "CEREBRAS_API_KEY",
        "XAI_API_KEY",
        "OPENROUTER_API_KEY",
        "HF_TOKEN",
    },
}


@dataclass(frozen=True)
class ProviderConfig:
    provider: str
    model: str
    command: str = "archon"

    @classmethod
    def resolve(
        cls,
        environ: Mapping[str, str],
        provider: str | None = None,
        model: str | None = None,
        command: str | None = None,
    ) -> "ProviderConfig":
        selected = (provider or environ.get("AI_PROVIDER") or "codex").lower()
        if selected not in SUPPORTED_PROVIDERS:
            supported = ", ".join(SUPPORTED_PROVIDERS)
            raise ConfigError(f"unsupported AI provider {selected!r}; choose {supported}")
        return cls(
            provider=selected,
            model=model or environ.get("AI_MODEL") or DEFAULT_MODELS[selected],
            command=command or environ.get("ARCHON_COMMAND") or "archon",
        )

    def auth_status(self, environ: Mapping[str, str]) -> tuple[bool, str]:
        home = Path(environ.get("HOME", ""))
        if self.provider == "codex":
            codex_home = Path(environ.get("CODEX_HOME", home / ".codex"))
            if environ.get("OPENAI_API_KEY") or (codex_home / "auth.json").is_file():
                return True, "Codex authentication found"
            return False, "Codex authentication missing; run `codex login` or set OPENAI_API_KEY"
        if self.provider == "claude":
            if environ.get("ANTHROPIC_API_KEY") or (home / ".claude" / ".credentials.json").is_file():
                return True, "Claude authentication found"
            return False, "Claude authentication missing; run `claude` and /login or set ANTHROPIC_API_KEY"
        model_backend = self.model.split("/", 1)[0].upper().replace("-", "_")
        key = {"GOOGLE": "GEMINI_API_KEY", "HUGGINGFACE": "HF_TOKEN"}.get(
            model_backend, f"{model_backend}_API_KEY"
        )
        pi_config = Path(environ.get("PI_CONFIG_DIR", home / ".pi" / "agent"))
        if environ.get(key) or (pi_config / "auth.json").is_file():
            return True, f"Pi authentication found for {self.model}"
        return False, f"Pi authentication missing; run `pi /login` or set {key}"


def build_child_env(
    provider: str,
    process_env: Mapping[str, str],
    dotenv: Mapping[str, str],
    root: Path,
) -> dict[str, str]:
    allowed = COMMON_ENV | STORE_ENV | PROVIDER_ENV[provider]
    # Dotenv may supply Store Drop and provider credentials, but it must never
    # override process-control values such as HOME or PATH.
    child = {key: value for key, value in process_env.items() if key in allowed and value != ""}
    for key in STORE_ENV | PROVIDER_ENV[provider]:
        if dotenv.get(key, "") != "":
            child[key] = dotenv[key]
    child["STORE_DROP_ROOT"] = str(root)
    child["PYTHONPATH"] = str(root)
    child["AI_PROVIDER"] = provider
    return child


def make_run_config(config: ProviderConfig) -> str:
    # Provider/model are validated to single-line scalar values before this call.
    if any(c in config.model for c in "\r\n"):
        raise ConfigError("AI model must be a single line")
    return (
        f"assistant: {config.provider}\n"
        "assistants:\n"
        f"  {config.provider}:\n"
        f"    model: {config.model!r}\n"
    )


def require_archon_version(executable: str) -> tuple[int, int, int]:
    result = subprocess.run(
        [executable, "version"], capture_output=True, text=True, check=False, timeout=10
    )
    match = re.search(r"Archon CLI v(\d+)\.(\d+)\.(\d+)", result.stdout + result.stderr)
    if not match:
        raise ConfigError("could not determine Archon version; Store Drop requires 0.10.1+")
    version = tuple(int(part) for part in match.groups())
    if version < MIN_ARCHON_VERSION:
        found = ".".join(str(part) for part in version)
        raise ConfigError(f"Archon {found} is too old; Store Drop requires 0.10.1+")
    return version


def describe(config: ProviderConfig, env: Mapping[str, str], dotenv: Mapping[str, str]) -> str:
    auth_ok, auth_message = config.auth_status({**env, **dotenv})
    lines = [
        f"provider: {config.provider}",
        f"model: {config.model}",
        f"runner: {config.command}",
        f"authentication: {'ready' if auth_ok else 'required'} ({auth_message})",
        "bridge configuration:",
    ]
    for key in ("BRIDGE_URL", "BRIDGE_USER", "BRIDGE_PASS", "BRIDGE_SITE"):
        lines.append(f"  {key}: {redact(dotenv.get(key))}")
    return "\n".join(lines)


def run_archon(
    root: Path,
    config: ProviderConfig,
    dotenv: Mapping[str, str],
    extra_args: Sequence[str] = (),
    check_auth: bool = True,
) -> int:
    current = dict(os.environ)
    if check_auth:
        ready, message = config.auth_status({**dotenv, **current})
        if not ready:
            raise ConfigError(message)
    executable = shutil.which(config.command, path=current.get("PATH"))
    if not executable:
        raise ConfigError(f"Archon command not found: {config.command!r}")
    require_archon_version(executable)
    child_env = build_child_env(config.provider, current, dotenv, root)
    child_env["AI_MODEL"] = config.model
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".yaml") as handle:
        handle.write(make_run_config(config))
        handle.flush()
        argv = [
            executable,
            "workflow",
            "run",
            "deploy-pod-store",
            "--no-worktree",
            "--config",
            handle.name,
            *extra_args,
        ]
        return subprocess.run(argv, cwd=root, env=child_env, check=False).returncode
