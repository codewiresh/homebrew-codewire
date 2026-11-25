# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "0.4.33"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/18a0b96836c586598bfb296cadc7b3b2ff76c4f018d4b3fd9d6306f5921bdd1d"
      sha256 "18a0b96836c586598bfb296cadc7b3b2ff76c4f018d4b3fd9d6306f5921bdd1d"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/d5dd76b473cb7a87e5ae8d1aa4f622a9002cba3600f8dc5a1216dfa4a610d554"
      sha256 "d5dd76b473cb7a87e5ae8d1aa4f622a9002cba3600f8dc5a1216dfa4a610d554"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/692ab91511ffa3cd1bf2db6346adcf58c8189d35dfb897ea56345d1af3bb5648"
      sha256 "692ab91511ffa3cd1bf2db6346adcf58c8189d35dfb897ea56345d1af3bb5648"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/1d4c1878d544ff5b6c8f1763f7640bdbd977daa355e488be3dcd490268be1b24"
      sha256 "1d4c1878d544ff5b6c8f1763f7640bdbd977daa355e488be3dcd490268be1b24"
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
    assert_match "cw v#{version}", shell_output("#{bin}/cw --version")
  end
end
