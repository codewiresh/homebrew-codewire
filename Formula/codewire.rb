# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "0.4.28"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/49f0bb0def11f2214573a71b80d11c405c61e3bf923f80189ffdea3bc2c9caaa"
      sha256 "49f0bb0def11f2214573a71b80d11c405c61e3bf923f80189ffdea3bc2c9caaa"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/1d13a49b49d8ca1362aae1f7464ef361ae37df733e862b1bb8c5dcf94760c778"
      sha256 "1d13a49b49d8ca1362aae1f7464ef361ae37df733e862b1bb8c5dcf94760c778"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/063aaf570f54cf5de4e8f14254e5e1a54653055ea59de3376e1b89a5e5104662"
      sha256 "063aaf570f54cf5de4e8f14254e5e1a54653055ea59de3376e1b89a5e5104662"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/001abcf18f97db3e34224fab550486a2176c02d17d64e4b99a4c3e3defd2537d"
      sha256 "001abcf18f97db3e34224fab550486a2176c02d17d64e4b99a4c3e3defd2537d"
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
