# Homebrew formula for the Codewire CLI (cw).
#
# Each platform downloads the exact release blob that install.sh uses, by its
# sha256 from the release's SHA256SUMS on releases.codewire.sh.
class Codewire < Formula
  desc "Run coding agents in cloud and local sandboxes"
  homepage "https://codewire.sh"
  version "0.4.25"
  license "AGPL-3.0-only"

  on_macos do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/8b0d9d3b5e06b6ef7586f3b37451a1c4d560c87008dbdcd7c1c6ae32e7f89390"
      sha256 "8b0d9d3b5e06b6ef7586f3b37451a1c4d560c87008dbdcd7c1c6ae32e7f89390"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/42b9d883f7a6d7463dddf457949cd2cec11d79912db147661aae670637c5dc3a"
      sha256 "42b9d883f7a6d7463dddf457949cd2cec11d79912db147661aae670637c5dc3a"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/e850311979bfcc82780c8c3751a09f8a30fdf99ef2a3eb5250995aab4796a0da"
      sha256 "e850311979bfcc82780c8c3751a09f8a30fdf99ef2a3eb5250995aab4796a0da"
    else
      url "https://releases.codewire.sh/cw/v1/blobs/sha256/9b2e80f89a11fbd31722207aa9c1bf418d1f56148ce8329466bfb6249b82b4eb"
      sha256 "9b2e80f89a11fbd31722207aa9c1bf418d1f56148ce8329466bfb6249b82b4eb"
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
