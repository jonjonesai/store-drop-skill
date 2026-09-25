import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path

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
    def test_codex_is_default_and_claude_is_supported(self):
        self.assertEqual(ProviderConfig.resolve({}).provider, "codex")
        self.assertEqual(ProviderConfig.resolve({}, "claude").model, "sonnet")

    def test_unknown_provider_fails(self):
        with self.assertRaisesRegex(ConfigError, "unsupported AI provider"):
            ProviderConfig.resolve({}, "mystery")

    def test_custom_provider_config_directories_are_detected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            codex_home = root / "codex"
            pi_config = root / "pi"
            codex_home.mkdir()
            pi_config.mkdir()
            (codex_home / "auth.json").touch()
            (pi_config / "auth.json").touch()
            self.assertTrue(
                ProviderConfig("codex", "gpt-test").auth_status(
                    {"HOME": str(root), "CODEX_HOME": str(codex_home)}
                )[0]
            )
            self.assertTrue(
                ProviderConfig("pi", "openai/gpt-test").auth_status(
                    {"HOME": str(root), "PI_CONFIG_DIR": str(pi_config)}
                )[0]
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
