import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from store_drop.config import ConfigError, parse_dotenv_text
from store_drop.provider import ProviderConfig, build_child_env, describe, make_run_config, require_archon_version


class DotenvTests(unittest.TestCase):
    def test_spaces_quotes_hashes_and_empty_values(self):
        parsed = parse_dotenv_text(
            """\
BRIDGE_PASS=xxxx xxxx # comment
QUOTED="value with spaces # kept"
SINGLE='literal # value'
URL=https://example.test/#fragment
EMPTY=
export COLOR=#D42945
"""
        )
        self.assertEqual(parsed["BRIDGE_PASS"], "xxxx xxxx")
        self.assertEqual(parsed["QUOTED"], "value with spaces # kept")
        self.assertEqual(parsed["SINGLE"], "literal # value")
        self.assertEqual(parsed["URL"], "https://example.test/#fragment")
        self.assertEqual(parsed["EMPTY"], "")
        self.assertEqual(parsed["COLOR"], "#D42945")

    def test_does_not_expand_or_execute_shell(self):
        parsed = parse_dotenv_text("VALUE=$(touch /tmp/store-drop-must-not-exist)\nHOME=$HOME\n")
        self.assertEqual(parsed["VALUE"], "$(touch /tmp/store-drop-must-not-exist)")
        self.assertEqual(parsed["HOME"], "$HOME")

    def test_invalid_input_fails_precisely(self):
        with self.assertRaisesRegex(ConfigError, "line 1"):
            parse_dotenv_text("NOT A KEY=value")


class ProviderTests(unittest.TestCase):
    def test_direct_runner_falls_back_to_codex_and_supports_claude(self):
        self.assertEqual(ProviderConfig.resolve({}).provider, "codex")
        self.assertEqual(ProviderConfig.resolve({}, "claude").model, "sonnet")

    def test_unknown_provider_fails(self):
        with self.assertRaisesRegex(ConfigError, "unsupported AI provider"):
            ProviderConfig.resolve({}, "mystery")

    def test_switching_provider_does_not_reuse_stale_model(self):
        config = ProviderConfig.resolve(
            {"AI_PROVIDER": "pi", "AI_MODEL": "openai/old-model"}, "claude"
        )
        self.assertEqual(config.provider, "claude")
        self.assertEqual(config.model, "sonnet")

    def test_saved_model_is_used_when_provider_matches(self):
        config = ProviderConfig.resolve(
            {"AI_PROVIDER": "claude", "AI_MODEL": "opus"}, "claude"
        )
        self.assertEqual(config.model, "opus")

    def test_custom_pi_config_directory_is_detected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            pi_config = root / "pi"
            pi_config.mkdir()
            (pi_config / "auth.json").write_text(
                '{"openai": {"type": "api_key"}}', encoding="utf-8"
            )
            self.assertTrue(
                ProviderConfig("pi", "openai/gpt-test").auth_status(
                    {"HOME": str(root), "PI_CONFIG_DIR": str(pi_config)}
                )[0]
            )

    def test_pi_auth_file_must_contain_selected_backend(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            auth = root / "auth.json"
            auth.write_text('{"anthropic": {"type": "oauth"}}', encoding="utf-8")
            self.assertFalse(
                ProviderConfig("pi", "openai/gpt-test").auth_status(
                    {"HOME": str(root), "PI_CONFIG_DIR": str(root), "PATH": ""}
                )[0]
            )
            self.assertTrue(
                ProviderConfig("pi", "anthropic/claude-test").auth_status(
                    {"HOME": str(root), "PI_CONFIG_DIR": str(root), "PATH": ""}
                )[0]
            )

    def test_model_ids_are_validated_before_preflight(self):
        with self.assertRaisesRegex(ConfigError, "without whitespace"):
            ProviderConfig.resolve({}, "codex", "bad model")
        with self.assertRaisesRegex(ConfigError, "backend/model"):
            ProviderConfig.resolve({}, "pi", "missing-backend-separator")

    @patch.object(ProviderConfig, "provider_executable", return_value="/bin/codex")
    @patch("store_drop.provider.subprocess.run")
    def test_codex_cli_status_is_used_without_exposing_output(self, run, _executable):
        run.return_value = SimpleNamespace(returncode=0)
        ready, _ = ProviderConfig("codex", "gpt-test").auth_status(
            {"HOME": "/home/test", "PATH": "/bin"}
        )
        self.assertTrue(ready)
        self.assertEqual(run.call_args.args[0], ["/bin/codex", "login", "status"])
        self.assertTrue(run.call_args.kwargs["capture_output"])

    def test_missing_provider_command_names_exact_override(self):
        with self.assertRaisesRegex(ConfigError, "CODEX_BIN_PATH"):
            ProviderConfig("codex", "gpt-test").require_provider_executable(
                {"PATH": ""}
            )

    def test_child_environment_is_allowlisted(self):
        env = {
            "HOME": "/home/test",
            "PATH": "/bin",
            "OPENAI_API_KEY": "provider-secret",
            "UNRELATED_SECRET": "must-not-pass",
        }
        dotenv = {"BRIDGE_PASS": "wp-secret", "ALSO_UNRELATED": "no", "HOME": "/attacker"}
        child = build_child_env("codex", env, dotenv, Path("/repo"))
        self.assertEqual(child["OPENAI_API_KEY"], "provider-secret")
        self.assertEqual(child["BRIDGE_PASS"], "wp-secret")
        self.assertNotIn("UNRELATED_SECRET", child)
        self.assertNotIn("ALSO_UNRELATED", child)
        self.assertEqual(child["HOME"], "/home/test")

    def test_run_config_is_provider_specific_not_workflow_specific(self):
        text = make_run_config(ProviderConfig("codex", "gpt-test"))
        self.assertIn("assistant: codex", text)
        self.assertIn("model: 'gpt-test'", text)

    def test_dry_run_description_redacts_secret_values(self):
        config = ProviderConfig("codex", "gpt-test")
        text = describe(config, {"HOME": "/missing"}, {"BRIDGE_PASS": "super-secret"})
        self.assertIn("BRIDGE_PASS: <set>", text)
        self.assertNotIn("super-secret", text)

    @patch("store_drop.provider.subprocess.run")
    def test_old_archon_fails_before_workflow_execution(self, run):
        run.return_value.stdout = "Archon CLI v0.3.10"
        run.return_value.stderr = ""
        with self.assertRaisesRegex(ConfigError, "too old"):
            require_archon_version("archon")


if __name__ == "__main__":
    unittest.main()
