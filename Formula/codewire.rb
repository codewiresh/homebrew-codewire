# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "0.4.35"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/c80621aea8c8b09e79bc0d4bea713e625366052a8af7d0e142aea2c73cdd0627"
      sha256 "c80621aea8c8b09e79bc0d4bea713e625366052a8af7d0e142aea2c73cdd0627"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/182d19a00fdd0a2da6e117389785468b83b13cee157d58bd00f86a3fe156ef13"
      sha256 "182d19a00fdd0a2da6e117389785468b83b13cee157d58bd00f86a3fe156ef13"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/321b0ee60f9bbb057568c70842e98e8beae28f56ad15cb0b0db3f7e14d51f4cb"
      sha256 "321b0ee60f9bbb057568c70842e98e8beae28f56ad15cb0b0db3f7e14d51f4cb"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/e00916a0fc080776099fdae6faf362b958bc32d6ee2c827a6aa619b82e86a85d"
      sha256 "e00916a0fc080776099fdae6faf362b958bc32d6ee2c827a6aa619b82e86a85d"
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
