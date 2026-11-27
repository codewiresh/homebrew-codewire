# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "0.4.36"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/ca95d27585294fe364704279fbeafd0c661f966f9ac78e90c76d018af216d486"
      sha256 "ca95d27585294fe364704279fbeafd0c661f966f9ac78e90c76d018af216d486"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/81524b70861f8fd97cb2124ed27c06ea1e652146dec1e45d6946c3ff46be0722"
      sha256 "81524b70861f8fd97cb2124ed27c06ea1e652146dec1e45d6946c3ff46be0722"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/7ff2a295c46d20aaa31df9f157184aec3c5c6a66299a9e80308dc9e7b4729fef"
      sha256 "7ff2a295c46d20aaa31df9f157184aec3c5c6a66299a9e80308dc9e7b4729fef"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/d1793c20955d273919998c616556f4b287a5d7d01defe90dfdda66395a1449ee"
      sha256 "d1793c20955d273919998c616556f4b287a5d7d01defe90dfdda66395a1449ee"
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
