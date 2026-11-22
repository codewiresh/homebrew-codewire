# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "0.4.30"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/d821d24fbd4beee29fa90d1f74e65f70c6c46b337dce4f0449c3dce4dd4965be"
      sha256 "d821d24fbd4beee29fa90d1f74e65f70c6c46b337dce4f0449c3dce4dd4965be"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/9c76a7d6e501ea08140f2cc4bf1954cc9528c152ab50554aaeb4f3812a69aab2"
      sha256 "9c76a7d6e501ea08140f2cc4bf1954cc9528c152ab50554aaeb4f3812a69aab2"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/cded3b17957d2f57909c68f03809630812ba3b0608ef2b320804e8c158fe5f85"
      sha256 "cded3b17957d2f57909c68f03809630812ba3b0608ef2b320804e8c158fe5f85"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/08a2c92ca8f8392383adfe0c4cc627cf2a8a6ba005abca61328940092c8ecd53"
      sha256 "08a2c92ca8f8392383adfe0c4cc627cf2a8a6ba005abca61328940092c8ecd53"
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
