# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "0.4.41"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/aa9cfc93229b99ebe65948059b53b84598fc7c9a42949e6c045f5642d4099a5a"
      sha256 "aa9cfc93229b99ebe65948059b53b84598fc7c9a42949e6c045f5642d4099a5a"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/feb47e48efb35d2e3b1c221f2e711d700dbde686af27d9441168b29a2691e881"
      sha256 "feb47e48efb35d2e3b1c221f2e711d700dbde686af27d9441168b29a2691e881"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/1d61ec902830ca65bc2046c5ff4168e9e58f2a98e575d56f3ffaf0370319d6df"
      sha256 "1d61ec902830ca65bc2046c5ff4168e9e58f2a98e575d56f3ffaf0370319d6df"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/b806ecd0c9688b536fbcb9c4e0162fc41d6b42e418c8742ea764b7edca6c5776"
      sha256 "b806ecd0c9688b536fbcb9c4e0162fc41d6b42e418c8742ea764b7edca6c5776"
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
