# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "0.4.26"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/8bac02c99f9bd8ad3d4e903abeef2ecfbd9b0eab3da46d86f2cade8c37ec88e6"
      sha256 "8bac02c99f9bd8ad3d4e903abeef2ecfbd9b0eab3da46d86f2cade8c37ec88e6"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/638e2a680852e5a21a6f65395f57235d5faa703b169ee6bb7049716cd92a599d"
      sha256 "638e2a680852e5a21a6f65395f57235d5faa703b169ee6bb7049716cd92a599d"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/f5c798188ea8fb71aeb1a8397e710e8617dd86d7167cb48eec0fe88cfdc249d5"
      sha256 "f5c798188ea8fb71aeb1a8397e710e8617dd86d7167cb48eec0fe88cfdc249d5"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/074540edb00732554ceeb593f974319e1d287aaf589654554a27058b3fbfc852"
      sha256 "074540edb00732554ceeb593f974319e1d287aaf589654554a27058b3fbfc852"
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
