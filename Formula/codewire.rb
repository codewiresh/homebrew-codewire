# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "0.4.31"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/8063f2ade787a1161f0976b6679a449e4011c33fb666c3797fb70b7a0cd2e126"
      sha256 "8063f2ade787a1161f0976b6679a449e4011c33fb666c3797fb70b7a0cd2e126"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/552eb580ff47826a031da3313a777c94e829b8273796ef4b05f618f6179a169a"
      sha256 "552eb580ff47826a031da3313a777c94e829b8273796ef4b05f618f6179a169a"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/3981faead6c3abcca8f1f90fa380dc5228df6903cef5c94f5b9e3b8ae594c718"
      sha256 "3981faead6c3abcca8f1f90fa380dc5228df6903cef5c94f5b9e3b8ae594c718"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/f43e899cc7339b20e9224f4ed19f7b1c98bd3ffd849c9862755ad2f534a9787f"
      sha256 "f43e899cc7339b20e9224f4ed19f7b1c98bd3ffd849c9862755ad2f534a9787f"
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
