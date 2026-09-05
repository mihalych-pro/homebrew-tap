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
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.4/dmt-0.2.4-darwin-amd64.tar.gz"
      sha256 "8c96c6fbb201be08be351c8a4f1e18aa60c8b720edc824b6029de19d245cfce2"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.4/dmt-0.2.4-darwin-arm64.tar.gz"
      sha256 "953a2bc045cd68081a85e2beaba0d8ea5d2b7322e9d8303395cf9b8374a7a303"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.4/dmt-0.2.4-linux-amd64.tar.gz"
      sha256 "b30df5775ae316d9f3e47e8665ee33dbdadbde69704826e7e63c2456acdffb9b"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.4/dmt-0.2.4-linux-arm64.tar.gz"
      sha256 "294775ebd8d0b493d0ad6c51cfccdc55baf92619dac12f22b009b81098e30c71"
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
