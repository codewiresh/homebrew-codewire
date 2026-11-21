# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "0.4.27"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/d0ae6813574df9f000feb0f2a770f10634e7749d5ac640b46ac2e2866cfd3950"
      sha256 "d0ae6813574df9f000feb0f2a770f10634e7749d5ac640b46ac2e2866cfd3950"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/09866cbecfc4f727cdd2c9e9b216eaf8ddd3e10787744a0fb9472542c5e52a3e"
      sha256 "09866cbecfc4f727cdd2c9e9b216eaf8ddd3e10787744a0fb9472542c5e52a3e"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/2af49f2769e3e8306fd8b058da3dd63c75d4322a5c474af9a1ee98022c37d798"
      sha256 "2af49f2769e3e8306fd8b058da3dd63c75d4322a5c474af9a1ee98022c37d798"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/ce2c5d9a18813a5a0610fff428e754a940ca68f4b4d90090cbd1b3eec7dcd7f7"
      sha256 "ce2c5d9a18813a5a0610fff428e754a940ca68f4b4d90090cbd1b3eec7dcd7f7"
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
