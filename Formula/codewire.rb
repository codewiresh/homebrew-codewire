# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "0.4.24"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/6873e413ee4bde3f24370596e4bfc3a69353835b0d17778b9a4ea387d3c5f36d"
      sha256 "6873e413ee4bde3f24370596e4bfc3a69353835b0d17778b9a4ea387d3c5f36d"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/6cf527dc4295b3563c9b2882c494eae138c90ac6fbf93650298b33a858823c85"
      sha256 "6cf527dc4295b3563c9b2882c494eae138c90ac6fbf93650298b33a858823c85"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/3c3a624f622c626632d1c408d4af7b97c8b63c94b94e6d4927b342dcdb4821e6"
      sha256 "3c3a624f622c626632d1c408d4af7b97c8b63c94b94e6d4927b342dcdb4821e6"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/f9ee04db706c19fcc750d00842f6b9a939b73b02fec84edc891b9b0d33d15e8d"
      sha256 "f9ee04db706c19fcc750d00842f6b9a939b73b02fec84edc891b9b0d33d15e8d"
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
