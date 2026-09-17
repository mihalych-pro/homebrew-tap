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
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.5/dmt-0.2.5-darwin-amd64.tar.gz"
      sha256 "5cdd1e07db6b5e8ff05787cbbc2b316c712e7065c0bb66acc59820708a8933be"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.5/dmt-0.2.5-darwin-arm64.tar.gz"
      sha256 "3590434bd13124cf09fe9dbb0a74581278705601be5e18ae436ba25682a79d57"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.5/dmt-0.2.5-linux-amd64.tar.gz"
      sha256 "ab781e4d1de7a1f12c06efca588605fb636ab7953217cbddbe7cb8bd799c7eb1"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.5/dmt-0.2.5-linux-arm64.tar.gz"
      sha256 "0d45abf4ad08f3dd2fc0a93c924ebabebee23568f02a5970ba417ddeab6be9ca"
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
