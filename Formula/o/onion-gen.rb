class OnionGen < Formula
  desc "Vanity address generator for Tor Onion Service v3"
  homepage "https://github.com/mihalych-pro/onion-gen"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  # Upstream publishes a `<asset>.sha256` beside every binary; the bump script
  # checks each download against it before writing the checksum here.
  on_macos do
    on_intel do
      url "https://github.com/mihalych-pro/onion-gen/releases/download/v1.0.2/onion-gen-darwin-amd64"
      sha256 "fff58216ee37c3416407d3677609f6714355d9c8842875c8da52bdf1d23ff79a"
    end
    on_arm do
      url "https://github.com/mihalych-pro/onion-gen/releases/download/v1.0.2/onion-gen-darwin-arm64"
      sha256 "1726864eee5b4a11153ed8762dbd4b2f1842e9b2399dfa3a1f4ee911884abcfa"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/mihalych-pro/onion-gen/releases/download/v1.0.2/onion-gen-linux-amd64"
      sha256 "cb9d9b45553ea6133925af4acb277d7cfe1c261a1cab7862ef072fbe1e8ee471"
    end
    on_arm do
      url "https://github.com/mihalych-pro/onion-gen/releases/download/v1.0.2/onion-gen-linux-arm64"
      sha256 "c24a3ca87f170c62ca928647889968bca90fcc4ec09dd90bb53fb5ff981231c7"
    end
  end

  def install
    # The release asset is a bare binary named after its platform.
    bin.install Dir["onion-gen-*"].first => "onion-gen"
    # A downloaded file has no executable bit, and Cleaner only keeps a bit
    # that is already set.
    chmod 0555, bin/"onion-gen"
  end

  test do
    assert_match "onion-gen #{version}", shell_output("#{bin}/onion-gen --version")

    # A two-symbol prefix is found within a second on one thread. The card is
    # left alone so the test does not depend on a GPU driver.
    address = shell_output("#{bin}/onion-gen --compute cpu --threads 1 --limit 1 " \
                           "--quiet-diagnostics --filter ab --out-dir #{testpath}/keys").strip
    assert_match(/\Aab[a-z2-7]{54}\.onion\z/, address)
    assert_equal "#{address}\n", (testpath/"keys/#{address}/hostname").read

    assert_match "1 key(s) checked, 0 failed", shell_output("#{bin}/onion-gen verify #{testpath}/keys")
  end
end
