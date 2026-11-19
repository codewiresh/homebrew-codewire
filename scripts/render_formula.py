#!/usr/bin/env python3
"""Write Formula/codewire.rb for a signed Codewire release.

  render --version vX.Y.Z --output Formula/codewire.rb
      for the release the stable channel names, under the release key's
      signature; refuses a version older than the formula's
  check FORMULA
      the formula is exactly the one its version's signed SHA256SUMS renders

Every digest comes from the release's SHA256SUMS on releases.codewire.sh,
checked against SHA256SUMS.asc with keys/codewire-release.asc, which must hold
exactly the primary key FINGERPRINT. Each download is the blob with that
digest, the same bytes install.sh installs. Uses only Python's standard
library and gpg.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path

ORIGIN = "https://releases.codewire.sh"
FINGERPRINT = "A38FF6BC6623FCA611A7A32B5EFBF0F4A5870815"
KEY_FILE = Path(__file__).resolve().parent.parent / "keys" / "codewire-release.asc"
CHANNEL_SCHEMA = "codewire.cw.channel/v1"
MAX_JSON = 64 * 1024
MAX_SIGNATURE = 16 * 1024
VERSION = re.compile(r"v([0-9]+)\.([0-9]+)\.([0-9]+)")
SUMS_LINE = re.compile(r"([0-9a-f]{64})  (cw-v[0-9]+\.[0-9]+\.[0-9]+-[0-9a-z_-]+)")
FORMULA_VERSION = re.compile(r'^  version "([0-9]+\.[0-9]+\.[0-9]+)"$', re.M)
TARGETS = ("aarch64-apple-darwin", "x86_64-apple-darwin", "aarch64-unknown-linux-gnu", "x86_64-unknown-linux-musl")

FORMULA = '''# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "{version}"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "{origin}/cw/v1/blobs/sha256/{aarch64-apple-darwin}"
      sha256 "{aarch64-apple-darwin}"
    else
      url "{origin}/cw/v1/blobs/sha256/{x86_64-apple-darwin}"
      sha256 "{x86_64-apple-darwin}"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "{origin}/cw/v1/blobs/sha256/{aarch64-unknown-linux-gnu}"
      sha256 "{aarch64-unknown-linux-gnu}"
    else
      url "{origin}/cw/v1/blobs/sha256/{x86_64-unknown-linux-musl}"
      sha256 "{x86_64-unknown-linux-musl}"
    end
  end

  def install
    # The blob URL has no file name, so the download is the only file staged.
    downloads = buildpath.children.select(&:file?)
    odie "expected exactly one downloaded cw binary" if downloads.length != 1
    downloads.first.chmod 0755
    bin.install downloads.first => "cw"
    generate_completions_from_executable(bin/"cw", "completion")
  end

  def caveats
    <<~EOS
      Get started with:
        cw setup
    EOS
  end

  test do
    assert_match "cw v#{{version}}", shell_output("#{{bin}}/cw --version")
  end
end
'''


class FormulaError(Exception):
    pass


def require(condition, reason):
    if not condition:
        raise FormulaError(reason)


def log(message):
    print(f"render-formula: {message}", file=sys.stderr, flush=True)


def version_key(version):
    match = VERSION.fullmatch(version)
    require(match is not None, f"{version!r} is not vMAJOR.MINOR.PATCH")
    return tuple(int(part) for part in match.groups())


def fetch(path, limit):
    """GET ORIGIN/path, refusing anything but a 200 within limit bytes."""
    request = urllib.request.Request(f"{ORIGIN}/{path}", headers={"User-Agent": "codewire-homebrew-tap"})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            body = response.read(limit + 1)
    except (urllib.error.URLError, OSError) as error:
        raise FormulaError(f"reading {path} failed: {error}") from error
    require(len(body) <= limit, f"{path} is larger than {limit} bytes")
    return body


def verify(data, signature, key_file=KEY_FILE, fingerprint=FINGERPRINT):
    """One valid detached signature over data by exactly the pinned primary key."""
    require(0 < len(signature) <= MAX_SIGNATURE, "the signature is empty or too large")
    # A short home keeps gpg-agent's socket path under the Unix socket limit.
    with tempfile.TemporaryDirectory(prefix="gpg.", dir="/tmp") as home:
        env = {"GNUPGHOME": home, "PATH": os.environ.get("PATH", "/usr/bin:/bin"), "LC_ALL": "C"}
        gpg = ["gpg", "--no-options", "--batch"]
        listed = subprocess.run([*gpg, "--with-colons", "--import-options", "show-only", "--import", str(key_file)],
                                env=env, capture_output=True, text=True, timeout=30)
        lines = listed.stdout.splitlines()
        primaries = [lines[i + 1].split(":")[9] for i, line in enumerate(lines)
                     if line.startswith("pub:") and i + 1 < len(lines) and lines[i + 1].startswith("fpr:")]
        require(listed.returncode == 0 and primaries == [fingerprint],
                "the key file does not hold exactly the pinned release key")
        subprocess.run([*gpg, "--import", str(key_file)], env=env, capture_output=True, check=True, timeout=30)
        data_path, sig_path = Path(home, "data"), Path(home, "data.asc")
        data_path.write_bytes(data)
        sig_path.write_bytes(signature)
        result = subprocess.run([*gpg, "--status-fd", "1", "--verify", str(sig_path), str(data_path)],
                                env=env, capture_output=True, text=True, timeout=30)
    status = [line.split() for line in result.stdout.splitlines() if line.startswith("[GNUPG:] ")]
    valid = [fields for fields in status if fields[1] == "VALIDSIG"]
    bad = [fields for fields in status if fields[1] in ("BADSIG", "ERRSIG", "EXPSIG", "EXPKEYSIG", "REVKEYSIG")]
    require(result.returncode == 0 and not bad and len(valid) == 1 and valid[0][-1] == fingerprint,
            "the signature is not a valid signature by the release key")


def canonical(value):
    return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True) + "\n").encode()


def stable_tag(get=fetch, **trust):
    """The release tag the stable channel names, under the release key's signature."""
    data = get("cw/v1/channels/stable.json", MAX_JSON)
    try:
        channel = json.loads(data)
    except ValueError as error:
        raise FormulaError("the stable channel is not JSON") from error
    require(isinstance(channel, dict) and set(channel) == {"schema", "pointer", "signature"}
            and channel["schema"] == CHANNEL_SCHEMA and canonical(channel) == data
            and isinstance(channel["pointer"], dict) and isinstance(channel["signature"], str),
            "the stable channel is not a canonical channel object")
    verify(canonical(channel["pointer"]), channel["signature"].encode("ascii"), **trust)
    tag = channel["pointer"].get("release_tag")
    require(isinstance(tag, str), "the stable channel names no release")
    version_key(tag)
    return tag


def signed_digests(version, get=fetch, **trust):
    """{target: SHA-256} from VERSION's SHA256SUMS, under its signature; it must
    list exactly the four release assets, once each."""
    version_key(version)
    sums = get(f"cw/v1/releases/{version}/SHA256SUMS", MAX_JSON)
    verify(sums, get(f"cw/v1/releases/{version}/SHA256SUMS.asc", MAX_SIGNATURE), **trust)
    listed = {}
    for line in sums.decode("ascii").splitlines():
        match = SUMS_LINE.fullmatch(line)
        require(match is not None, f"SHA256SUMS line is malformed: {line!r}")
        require(match.group(2) not in listed, f"SHA256SUMS names {match.group(2)} twice")
        listed[match.group(2)] = match.group(1)
    assets = {f"cw-{version}-{target}": target for target in TARGETS}
    require(set(listed) == set(assets), "SHA256SUMS does not list exactly the four release assets")
    return {target: listed[asset] for asset, target in assets.items()}


def formula(version, digests):
    return FORMULA.format(version=version[1:], origin=ORIGIN, **digests)


def formula_version(text):
    match = FORMULA_VERSION.search(text)
    require(match is not None, "the formula names no version")
    return f"v{match.group(1)}"


def render(version, output, get=fetch, **trust):
    version_key(version)
    if output.exists():
        current = formula_version(output.read_text())
        require(version_key(version) >= version_key(current),
                f"the formula is on {current}, newer than {version}; it never moves backwards")
    named = stable_tag(get, **trust)
    require(named == version, f"the stable channel names {named}, not {version}")
    text = formula(version, signed_digests(version, get, **trust))
    output.write_text(text)
    log(f"wrote {output} for {version}")


def check(path, get=fetch, **trust):
    text = path.read_text()
    version = formula_version(text)
    require(text == formula(version, signed_digests(version, get, **trust)),
            f"{path} is not the formula {version}'s signed SHA256SUMS renders")
    log(f"{path} is {version}'s signed release")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    commands = parser.add_subparsers(dest="command", required=True)
    render_args = commands.add_parser("render")
    render_args.add_argument("--version", required=True)
    render_args.add_argument("--output", required=True, type=Path)
    check_args = commands.add_parser("check")
    check_args.add_argument("formula", type=Path)
    args = parser.parse_args(argv)
    try:
        if args.command == "render":
            render(args.version, args.output)
        else:
            check(args.formula)
    except FormulaError as error:
        log(f"REJECT {error}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
