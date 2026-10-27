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
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.7/dmt-0.2.7-darwin-amd64.tar.gz"
      sha256 "d5add5561024e12bd633f1fe7981b487cb1e36e657a1c8b70d2ea44cfbc1a9a3"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.7/dmt-0.2.7-darwin-arm64.tar.gz"
      sha256 "9f8c7f664dc0af2bb2046c212263c54804c41ad8b92552385b6a1b2e360f1595"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.7/dmt-0.2.7-linux-amd64.tar.gz"
      sha256 "1d253fcfc5a8b101bd89a3e0a6d35f6c4d1b2fb8e41d56f52d9e5ac0aba138e3"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.7/dmt-0.2.7-linux-arm64.tar.gz"
      sha256 "8bc7eb541152822d36d12e4d06ce794335d9aecd451f425a7d250670391f2133"
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
