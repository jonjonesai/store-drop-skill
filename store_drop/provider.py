"""Provider selection and Archon runner contract."""

from __future__ import annotations

import json
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
    "codex": {"CODEX_HOME", "CODEX_BIN_PATH", "CODEX_ACCESS_TOKEN", "OPENAI_API_KEY"},
    "claude": {
        "CLAUDE_BIN_PATH",
        "CLAUDE_CONFIG_DIR",
        "ANTHROPIC_API_KEY",
        "ANTHROPIC_AUTH_TOKEN",
        "ANTHROPIC_OAUTH_TOKEN",
    },
    "pi": {
        "PI_BIN_PATH",
        "PI_CONFIG_DIR",
        "OPENAI_API_KEY",
        "ANTHROPIC_API_KEY",
        "ANTHROPIC_AUTH_TOKEN",
        "ANTHROPIC_OAUTH_TOKEN",
        "GEMINI_API_KEY",
        "DEEPSEEK_API_KEY",
        "NVIDIA_API_KEY",
        "COPILOT_GITHUB_TOKEN",
        "GROQ_API_KEY",
        "MISTRAL_API_KEY",
        "CEREBRAS_API_KEY",
        "XAI_API_KEY",
        "OPENROUTER_API_KEY",
        "AI_GATEWAY_API_KEY",
        "ZAI_API_KEY",
        "ZAI_CODING_CN_API_KEY",
        "OPENCODE_API_KEY",
        "RADIUS_API_KEY",
        "HF_TOKEN",
        "FIREWORKS_API_KEY",
        "TOGETHER_API_KEY",
        "BASETEN_API_KEY",
        "KIMI_API_KEY",
        "META_API_KEY",
        "MINIMAX_API_KEY",
        "MINIMAX_CN_API_KEY",
        "MOONSHOT_API_KEY",
        "QWEN_TOKEN_PLAN_API_KEY",
        "QWEN_TOKEN_PLAN_CN_API_KEY",
        "XIAOMI_API_KEY",
        "XIAOMI_TOKEN_PLAN_CN_API_KEY",
        "XIAOMI_TOKEN_PLAN_AMS_API_KEY",
        "XIAOMI_TOKEN_PLAN_SGP_API_KEY",
    },
}

PI_BACKEND_ENV = {
    "anthropic": "ANTHROPIC_API_KEY",
    "google": "GEMINI_API_KEY",
    "google-gemini": "GEMINI_API_KEY",
    "github-copilot": "COPILOT_GITHUB_TOKEN",
    "huggingface": "HF_TOKEN",
    "vercel-ai-gateway": "AI_GATEWAY_API_KEY",
    "opencode": "OPENCODE_API_KEY",
    "opencode-go": "OPENCODE_API_KEY",
    "kimi-coding": "KIMI_API_KEY",
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
        saved_provider = environ.get("AI_PROVIDER", "").lower()
        if model:
            selected_model = model
        elif provider and saved_provider != selected:
            # An explicit provider switch must not inherit the previous
            # provider's model from dotenv.
            selected_model = DEFAULT_MODELS[selected]
        else:
            selected_model = environ.get("AI_MODEL") or DEFAULT_MODELS[selected]
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._:/-]*", selected_model):
            raise ConfigError("AI model must be a non-empty model id without whitespace")
        if selected == "pi" and "/" not in selected_model:
            raise ConfigError("Pi model must use backend/model format")
        return cls(
            provider=selected,
            model=selected_model,
            command=command or environ.get("ARCHON_COMMAND") or "archon",
        )

    def provider_executable(self, environ: Mapping[str, str]) -> str | None:
        setting, fallback = {
            "codex": ("CODEX_BIN_PATH", "codex"),
            "claude": ("CLAUDE_BIN_PATH", "claude"),
            "pi": ("PI_BIN_PATH", "pi"),
        }[self.provider]
        candidate = environ.get(setting) or fallback
        return shutil.which(candidate, path=environ.get("PATH", ""))

    def auth_status(self, environ: Mapping[str, str]) -> tuple[bool, str]:
        home = Path(environ.get("HOME", ""))
        if self.provider == "codex":
            if environ.get("OPENAI_API_KEY") or environ.get("CODEX_ACCESS_TOKEN"):
                return True, "Codex authentication found"
            if self._cli_auth_ready(environ):
                return True, "Codex authentication found"
            return False, "Codex authentication missing; run `codex login` or set OPENAI_API_KEY"
        if self.provider == "claude":
            if any(
                environ.get(key)
                for key in ("ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_OAUTH_TOKEN")
            ):
                return True, "Claude authentication found"
            if self._cli_auth_ready(environ):
                return True, "Claude authentication found"
            return False, "Claude authentication missing; run `claude auth login` or set ANTHROPIC_API_KEY"
        model_backend = self.model.split("/", 1)[0].upper().replace("-", "_")
        backend = self.model.split("/", 1)[0].lower()
        key = PI_BACKEND_ENV.get(backend, f"{model_backend}_API_KEY")
        pi_config = Path(environ.get("PI_CONFIG_DIR", home / ".pi" / "agent"))
        if environ.get(key) or self._pi_auth_has_backend(pi_config / "auth.json", self.model):
            return True, f"Pi authentication found for {self.model}"
        return False, f"Pi authentication missing; run `pi /login` or set {key}"

    def _cli_auth_ready(self, environ: Mapping[str, str]) -> bool:
        executable = self.provider_executable(environ)
        if not executable or self.provider == "pi":
            return False
        argv = {
            "codex": [executable, "login", "status"],
            "claude": [executable, "auth", "status", "--json"],
        }[self.provider]
        allowed = COMMON_ENV | PROVIDER_ENV[self.provider]
        status_env = {key: value for key, value in environ.items() if key in allowed and value}
        try:
            result = subprocess.run(
                argv,
                capture_output=True,
                text=True,
                check=False,
                timeout=10,
                env=status_env,
            )
        except (OSError, subprocess.TimeoutExpired):
            return False
        return result.returncode == 0

    @staticmethod
    def _pi_auth_has_backend(path: Path, model: str) -> bool:
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return False
        backend = model.split("/", 1)[0].lower()
        return isinstance(data, dict) and backend in {str(key).lower() for key in data}

    def require_provider_executable(self, environ: Mapping[str, str]) -> str:
        executable = self.provider_executable(environ)
        if not executable:
            setting = {
                "codex": "CODEX_BIN_PATH",
                "claude": "CLAUDE_BIN_PATH",
                "pi": "PI_BIN_PATH",
            }[self.provider]
            raise ConfigError(
                f"selected provider command not found: {self.provider}; "
                f"install it or configure {setting}"
            )
        return executable


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
