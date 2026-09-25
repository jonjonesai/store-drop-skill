import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEPLOY = ROOT / "deploy.sh"


class OnboardingEntrypointTests(unittest.TestCase):
    def run_deploy(
        self,
        *args: str,
        deploy: Path = DEPLOY,
        env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(deploy), *args],
            cwd=deploy.parent,
            input="",
            capture_output=True,
            text=True,
            check=False,
            timeout=10,
            env=env,
        )

    def test_invalid_explicit_provider_fails_before_site_access(self):
        result = self.run_deploy("--provider", "mystery")
        output = result.stdout + result.stderr
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unsupported AI provider", output)
        self.assertNotIn("Bridge credentials", output)

    def test_unattended_pi_requires_explicit_model(self):
        result = self.run_deploy("--provider", "pi")
        output = result.stdout + result.stderr
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Pi automation requires --model backend/model", output)
        self.assertNotIn("Bridge credentials", output)

    def test_runtime_preflight_completes_before_bridge_prompt(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            shutil.copy2(DEPLOY, root / "deploy.sh")
            shutil.copytree(ROOT / "scripts", root / "scripts")
            shutil.copytree(ROOT / "store_drop", root / "store_drop")
            fake_bin = root / "bin"
            fake_bin.mkdir()
            for name, body in {
                "codex": "#!/bin/sh\nexit 0\n",
                "archon": "#!/bin/sh\nprintf 'Archon CLI v0.10.1\\n'\n",
            }.items():
                executable = fake_bin / name
                executable.write_text(body, encoding="utf-8")
                executable.chmod(0o755)
            env = {
                "HOME": str(root / "home"),
                "PATH": f"{fake_bin}:/usr/bin:/bin",
                "LANG": "C.UTF-8",
            }
            result = self.run_deploy(
                "--provider", "codex", deploy=root / "deploy.sh", env=env
            )
            output = result.stdout + result.stderr
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("runtime preflight: ready (codex, gpt-5.6-sol)", output)
            self.assertIn("Bridge credentials", output)
            self.assertLess(
                output.index("runtime preflight: ready"), output.index("Bridge credentials")
            )

    def test_unattended_run_can_use_saved_provider_and_model(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            shutil.copy2(DEPLOY, root / "deploy.sh")
            shutil.copytree(ROOT / "scripts", root / "scripts")
            shutil.copytree(ROOT / "store_drop", root / "store_drop")
            (root / ".env").write_text(
                "AI_PROVIDER=pi\nAI_MODEL=\n", encoding="utf-8"
            )
            result = self.run_deploy(deploy=root / "deploy.sh", env=os.environ.copy())
            output = result.stdout + result.stderr
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Pi automation requires --model backend/model", output)
            self.assertNotIn("Bridge credentials", output)


if __name__ == "__main__":
    unittest.main()
