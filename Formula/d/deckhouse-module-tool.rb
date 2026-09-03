# The binary is `dmt`; the formula is named after the upstream project so that
# `brew search deckhouse` finds it and it does not squat the short name.
class DeckhouseModuleTool < Formula
  desc "Linter, renderer and test runner for Deckhouse modules"
  homepage "https://github.com/deckhouse/dmt"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_intel do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.2/dmt-0.2.2-darwin-amd64.tar.gz"
      sha256 "21673b41513c05ec65cacd8470c28ee8cf10e4d248df366d351a0f3644873933"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.2/dmt-0.2.2-darwin-arm64.tar.gz"
      sha256 "578fd87831acf3b6ae6ffcaabca3696bede9afa3c8cfeeb59d2b0597510aa9e9"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.2/dmt-0.2.2-linux-amd64.tar.gz"
      sha256 "d639c90ff08e506e0bfa5488f26a58b52e93c8567c3b279371412eb8b7b97e3e"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.2/dmt-0.2.2-linux-arm64.tar.gz"
      sha256 "0feec75b3e9f26e877113144345ca2135e206d67d9a5e362615c2275ecf5f7a2"
    end
  end

  def install
    bin.install "dmt"
  end

  test do
    assert_match "dmt version: v#{version}", shell_output("#{bin}/dmt --version")

    (testpath/"testmod/module.yaml").write <<~YAML
      name: testmod
      weight: 900
      namespace: d8-testmod
    YAML
    (testpath/"testmod/Chart.yaml").write <<~YAML
      name: testmod
      version: 0.0.1
    YAML

    # The module is deliberately incomplete: dmt must load it, run the linters
    # and exit non-zero with the findings it reported.
    output = shell_output("#{bin}/dmt lint #{testpath}/testmod 2>&1", 1)
    assert_match "definition-file", output
    assert_match "Lint failed", output
  end
end
