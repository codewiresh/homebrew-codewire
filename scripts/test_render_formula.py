#!/usr/bin/env python3
"""Synthetic proof for render_formula.py: a synthetic release key signs a
synthetic release, and every refusal is shown. Needs gpg and nothing on the
network."""
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import render_formula as rf  # noqa: E402


class Signer:
    """A throwaway primary key in its own short GNUPGHOME."""

    def __init__(self, name):
        self.home = tempfile.mkdtemp(prefix="tk.", dir="/tmp")
        self.env = {"GNUPGHOME": self.home, "PATH": os.environ.get("PATH", "/usr/bin:/bin"), "LC_ALL": "C"}
        self.gpg(["--passphrase", "", "--quick-gen-key", f"{name} <{name}@example.invalid>", "ed25519", "sign", "never"])
        listed = self.gpg(["--with-colons", "--list-keys"]).splitlines()
        self.fingerprint = next(line.split(":")[9] for line in listed if line.startswith("fpr:"))
        self.key_file = Path(self.home, "public.asc")
        self.key_file.write_text(self.gpg(["--armor", "--export", self.fingerprint]))

    def gpg(self, args, data=None):
        return subprocess.run(["gpg", "--batch", "--pinentry-mode", "loopback", *args], env=self.env, input=data,
                              capture_output=True, check=True, timeout=60, text=data is None or isinstance(data, str)).stdout

    def sign(self, data):
        return subprocess.run(["gpg", "--batch", "--pinentry-mode", "loopback", "--passphrase", "", "--armor",
                               "--detach-sign", "--local-user", self.fingerprint], env=self.env, input=data,
                              capture_output=True, check=True, timeout=60).stdout

    def close(self):
        subprocess.run(["gpgconf", "--kill", "all"], env=self.env, capture_output=True)
        shutil.rmtree(self.home, ignore_errors=True)


def digest(name):
    return hashlib.sha256(name.encode()).hexdigest()


class Release:
    """A synthetic origin: one release's SHA256SUMS and the stable channel."""

    def __init__(self, signer, version, stable=None, lines=None):
        self.objects = {}
        sums = lines if lines is not None else [f"{digest(t)}  cw-{version}-{t}" for t in sorted(rf.TARGETS)]
        sums = ("\n".join(sums) + "\n").encode()
        self.objects[f"cw/v1/releases/{version}/SHA256SUMS"] = sums
        self.objects[f"cw/v1/releases/{version}/SHA256SUMS.asc"] = signer.sign(sums)
        pointer = {"channel": "stable", "release_tag": stable or version}
        channel = {"schema": rf.CHANNEL_SCHEMA, "pointer": pointer,
                   "signature": signer.sign(rf.canonical(pointer)).decode("ascii")}
        self.objects["cw/v1/channels/stable.json"] = rf.canonical(channel)

    def get(self, path, limit):
        if path not in self.objects:
            raise rf.FormulaError(f"reading {path} failed: 404")
        return self.objects[path]


class RenderFormula(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.signer = Signer("release")
        cls.other = Signer("other")

    @classmethod
    def tearDownClass(cls):
        cls.signer.close()
        cls.other.close()

    def setUp(self):
        self.work = Path(tempfile.mkdtemp(prefix="rf.", dir="/tmp"))
        self.addCleanup(shutil.rmtree, self.work, True)
        self.trust = {"key_file": self.signer.key_file, "fingerprint": self.signer.fingerprint}
        self.output = self.work / "codewire.rb"

    def render(self, release, version="v1.2.3"):
        rf.render(version, self.output, release.get, **self.trust)

    def refuses(self, reason, release, version="v1.2.3"):
        with self.assertRaises(rf.FormulaError) as caught:
            self.render(release, version)
        self.assertIn(reason, str(caught.exception))

    def test_renders_each_target_by_its_signed_digest(self):
        self.render(Release(self.signer, "v1.2.3"))
        text = self.output.read_text()
        self.assertIn('  version "1.2.3"\n', text)
        for target in rf.TARGETS:
            self.assertIn(f'url "https://releases.codewire.sh/cw/v1/blobs/sha256/{digest(target)}"', text)
            self.assertIn(f'sha256 "{digest(target)}"', text)
        self.assertIn('assert_match "cw v#{version}", shell_output("#{bin}/cw --version")', text)
        rf.check(self.output, Release(self.signer, "v1.2.3").get, **self.trust)

    def test_the_same_version_rewrites_the_same_formula(self):
        release = Release(self.signer, "v1.2.3")
        self.render(release)
        before = self.output.read_bytes()
        self.render(release)
        self.assertEqual(before, self.output.read_bytes())

    def test_refuses_a_version_older_than_the_formula(self):
        self.render(Release(self.signer, "v1.2.3"))
        self.refuses("never moves backwards", Release(self.signer, "v1.2.2"), "v1.2.2")
        self.refuses("never moves backwards", Release(self.signer, "v1.1.9"), "v1.1.9")

    def test_refuses_a_release_the_stable_channel_does_not_name(self):
        self.refuses("the stable channel names v1.2.4, not v1.2.3", Release(self.signer, "v1.2.3", stable="v1.2.4"))

    def test_refuses_sums_signed_by_another_key(self):
        release = Release(self.signer, "v1.2.3")
        sums = release.objects["cw/v1/releases/v1.2.3/SHA256SUMS"]
        release.objects["cw/v1/releases/v1.2.3/SHA256SUMS.asc"] = self.other.sign(sums)
        self.refuses("not a valid signature by the release key", release)

    def test_refuses_tampered_sums(self):
        release = Release(self.signer, "v1.2.3")
        key = "cw/v1/releases/v1.2.3/SHA256SUMS"
        release.objects[key] = release.objects[key].replace(digest(rf.TARGETS[0]).encode(), b"0" * 64)
        self.refuses("not a valid signature by the release key", release)

    def test_refuses_a_channel_signed_by_another_key(self):
        release = Release(self.signer, "v1.2.3")
        channel = json.loads(release.objects["cw/v1/channels/stable.json"])
        channel["signature"] = self.other.sign(rf.canonical(channel["pointer"])).decode("ascii")
        release.objects["cw/v1/channels/stable.json"] = rf.canonical(channel)
        self.refuses("not a valid signature by the release key", release)

    def test_refuses_a_channel_that_is_not_canonical(self):
        release = Release(self.signer, "v1.2.3")
        channel = json.loads(release.objects["cw/v1/channels/stable.json"])
        release.objects["cw/v1/channels/stable.json"] = json.dumps(channel, indent=1).encode()
        self.refuses("not a canonical channel object", release)

    def test_refuses_a_key_file_holding_another_key(self):
        self.trust["key_file"] = self.other.key_file
        self.refuses("does not hold exactly the pinned release key", Release(self.signer, "v1.2.3"))

    def test_refuses_sums_without_exactly_the_four_assets(self):
        lines = [f"{digest(t)}  cw-v1.2.3-{t}" for t in rf.TARGETS]
        self.refuses("exactly the four release assets", Release(self.signer, "v1.2.3", lines=lines[:3]))
        extra = lines + [f"{digest('x')}  cw-v1.2.3-riscv64-unknown-linux-gnu"]
        self.refuses("exactly the four release assets", Release(self.signer, "v1.2.3", lines=extra))
        self.refuses("names cw-v1.2.3-", Release(self.signer, "v1.2.3", lines=lines + lines[:1]))
        self.refuses("malformed", Release(self.signer, "v1.2.3", lines=lines + ["not a sums line"]))

    def test_refuses_a_malformed_version(self):
        for version in ("1.2.3", "v1.2", "v1.2.3;x", "v1.2.3-rc.1"):
            self.refuses("is not vMAJOR.MINOR.PATCH", Release(self.signer, "v1.2.3"), version)

    def test_check_refuses_a_hand_edited_formula(self):
        release = Release(self.signer, "v1.2.3")
        self.render(release)
        self.output.write_text(self.output.read_text().replace(digest(rf.TARGETS[1]), "f" * 64))
        with self.assertRaises(rf.FormulaError) as caught:
            rf.check(self.output, release.get, **self.trust)
        self.assertIn("is not the formula v1.2.3's signed SHA256SUMS renders", str(caught.exception))


if __name__ == "__main__":
    unittest.main()
