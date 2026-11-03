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
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.9/dmt-0.2.9-darwin-amd64.tar.gz"
      sha256 "18894be0ced0f9fc189d082fc591bdc55639a5d21009eb1626204d327856b921"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.9/dmt-0.2.9-darwin-arm64.tar.gz"
      sha256 "6b47f53a5b1a2cf23db7a92a134012e8255af7e4a527a5e3214432e017bbed08"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.9/dmt-0.2.9-linux-amd64.tar.gz"
      sha256 "359f4e086dd2ca509051b474bc92ed25f6c93ffb97dec6027b33530f623c22db"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.9/dmt-0.2.9-linux-arm64.tar.gz"
      sha256 "8722c4e75d4f194bb186cfcbb9d020a3ec59ccb77a89a37b25dfb7eaa0d2b31b"
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
