# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "0.4.29"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/7e80345eebda2531222fd42ac7775410f8a4dfadb63382a69328661a011b5385"
      sha256 "7e80345eebda2531222fd42ac7775410f8a4dfadb63382a69328661a011b5385"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/51c78dbb3807f55eb677b334d59457156376c7dbfb2b3c9945634543178100c4"
      sha256 "51c78dbb3807f55eb677b334d59457156376c7dbfb2b3c9945634543178100c4"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/2e953b1c1bf071178143270863fc1656afb5845f0709b62a28b5bef46d6652ce"
      sha256 "2e953b1c1bf071178143270863fc1656afb5845f0709b62a28b5bef46d6652ce"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/cf4543a926b07b6aa6faa690984908ba84c6ec30f8c9d5e0ffaf5249ccfd0d6f"
      sha256 "cf4543a926b07b6aa6faa690984908ba84c6ec30f8c9d5e0ffaf5249ccfd0d6f"
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
