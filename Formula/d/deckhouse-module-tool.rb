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
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.6/dmt-0.2.6-darwin-amd64.tar.gz"
      sha256 "792533ca1a7f9abcac4848e9af68fb430dc038fe840e468b73debfce0283d64c"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.6/dmt-0.2.6-darwin-arm64.tar.gz"
      sha256 "336537d1236f6c72d9178e22c267d7deb464e875aedf0e8ecc8018a5f1522b9e"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.6/dmt-0.2.6-linux-amd64.tar.gz"
      sha256 "83aa00edec99f35bee77f337341ed86e2772d7b737cae577517a70b61e772f4f"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.6/dmt-0.2.6-linux-arm64.tar.gz"
      sha256 "62b08cace0d55bbe5255db450150ba82dc019e177dc0256d6aa02134538c08ea"
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
