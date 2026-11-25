# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "0.4.34"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/c76cf1a1cd31f918ca381fae0fd0446db3473cd90d26e44914a9b1991770c20f"
      sha256 "c76cf1a1cd31f918ca381fae0fd0446db3473cd90d26e44914a9b1991770c20f"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/d359c3e33292a0ef3033adc0d6febb95684d15c93c991482b3b1c46052a505c3"
      sha256 "d359c3e33292a0ef3033adc0d6febb95684d15c93c991482b3b1c46052a505c3"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/6994f947832c682b5162f4cf0971f4c93cd02873140dea89e61c7eef005c75e3"
      sha256 "6994f947832c682b5162f4cf0971f4c93cd02873140dea89e61c7eef005c75e3"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/26f23d7688671c648d58b4646512b3f8443644bb7e3d9d380c07ebc627447ceb"
      sha256 "26f23d7688671c648d58b4646512b3f8443644bb7e3d9d380c07ebc627447ceb"
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
