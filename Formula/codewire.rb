# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "0.4.32"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/34ccfbf6132c00419665d7f6abf322d245584ce38e2cb5fa194d2bebb18a1d7d"
      sha256 "34ccfbf6132c00419665d7f6abf322d245584ce38e2cb5fa194d2bebb18a1d7d"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/11a3eb4d4947436555d604d6dee7ba4e31dcc074290f6defb271f0443367180d"
      sha256 "11a3eb4d4947436555d604d6dee7ba4e31dcc074290f6defb271f0443367180d"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/b96c00794c6dc2258f47a0a621f27f51390493aff81993270064ea2325861ae5"
      sha256 "b96c00794c6dc2258f47a0a621f27f51390493aff81993270064ea2325861ae5"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/c2bb9334431d9669cf894345544f2f7cca16324232997294696a6fe8c6edbd12"
      sha256 "c2bb9334431d9669cf894345544f2f7cca16324232997294696a6fe8c6edbd12"
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
