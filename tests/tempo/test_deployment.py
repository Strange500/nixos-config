"""Evaluate the real Home Manager module, without activating it."""
import json
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]


class Deployment(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads(subprocess.check_output([
            "nix", "--extra-experimental-features", "nix-command flakes", "eval",
            "--json", str(ROOT) + "#homeConfigurations.hermes.config",
            "--apply", "c: { services = c.systemd.user.services; routes = c.qgroget.services; tmpfiles = c.systemd.user.tmpfiles.rules; }",
        ], text=True))

    def test_private_persistent_service(self):
        self.assertIn("tempo", self.config["services"], "Tempo service is not declared")
        unit = self.config["services"]["tempo"]
        self.assertEqual(unit["Install"]["WantedBy"], ["default.target"])
        self.assertEqual(unit["Service"]["Restart"], "on-failure")
        self.assertEqual(unit["Service"]["UMask"], "0077")
        self.assertEqual(unit["Service"]["LimitCORE"], 0)
        self.assertIn("sha256sum --check --status SHA256SUMS", unit["Service"]["ExecStartPre"])
        revision = (ROOT / "home/tempo/revision").read_text().strip()
        self.assertRegex(revision, r"^[0-9a-f]{40}$")
        self.assertEqual(unit["Service"]["WorkingDirectory"], "%h/.local/share/tempo/releases/" + revision)
        self.assertIn("app-password:%h/.config/tempo/password", unit["Service"]["LoadCredential"])
        env = unit["Service"]["Environment"]
        for setting in ["NODE_ENV=production", "HOST=127.0.0.1", "PORT=3100",
                        "APP_ORIGIN=https://edt.qgroget.com", "DATA_DIR=%h/.local/share/tempo/data"]:
            self.assertIn(setting, env)
        self.assertFalse(any("APP_PASSWORD=" in value for value in env))
        self.assertEqual(self.config["routes"]["edt"]["type"], "private")
        self.assertEqual(self.config["routes"]["edt"]["url"], "http://127.0.0.1:3100")
        self.assertEqual(self.config["routes"]["edt"]["subdomain"], "edt")
        self.assertIn("d %h/.local/share/tempo/data 0700 - - -", self.config["tmpfiles"])


if __name__ == "__main__":
    unittest.main()
