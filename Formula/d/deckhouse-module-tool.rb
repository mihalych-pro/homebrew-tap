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
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.8/dmt-0.2.8-darwin-amd64.tar.gz"
      sha256 "d9cd892b4a0251723b0525050dd7ee8d0f51e231ec3b94c5dad2359110ce8266"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.8/dmt-0.2.8-darwin-arm64.tar.gz"
      sha256 "02fe2fefdba5c98eda09ceba83a9d87fa8c6d3ed4813b4abcdf432d2f6839c49"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.8/dmt-0.2.8-linux-amd64.tar.gz"
      sha256 "0c4de38490fc32194753fe8d44c93bb24342d4e7ce1d984d8ada801cb5c93765"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.8/dmt-0.2.8-linux-arm64.tar.gz"
      sha256 "5296700a797aac2b002d19abdbf1540abcd055538c62c9ef406760fca5ce5783"
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
