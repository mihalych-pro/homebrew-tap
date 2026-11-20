# The binary is `dmt`; the formula is named after the upstream project so that
# `brew search deckhouse` finds it and it does not squat the short name.
class DeckhouseModuleTool < Formula
  desc "Linter, renderer and test runner for Deckhouse modules"
  homepage "https://github.com/deckhouse/dmt"
  license "Apache-2.0"

  livecheck do
    url :stable
    # The latest GitHub release rather than tags, which livecheck would read by
    # default: the binaries are release assets, and a tag has preceded its
    # release by up to a day (v0.2.8).
    strategy :github_latest
  end

  on_macos do
    on_intel do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.11/dmt-0.2.11-darwin-amd64.tar.gz"
      sha256 "d50b06f03483ee33d654fcbb89759f04afe304a6132a5d982e4211da21ae3e74"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.11/dmt-0.2.11-darwin-arm64.tar.gz"
      sha256 "c235bf879aaf97fa64e9c8501c812e1b0375fd9ed7f6d90da662b25c5c17bf4c"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.11/dmt-0.2.11-linux-amd64.tar.gz"
      sha256 "2069e08ecc122cf076f07a4521a81908bf31a1c548b7b31a2c90d24ab84a7f9b"
    end
    on_arm do
      url "https://github.com/deckhouse/dmt/releases/download/v0.2.11/dmt-0.2.11-linux-arm64.tar.gz"
      sha256 "8b3583cd78395e93a48214c6245bd3114a6a58fe24442a7ee8b94d9f4fd82a74"
    end
  end

  def install
    bin.install "dmt"
    generate_completions_from_executable(bin/"dmt", shell_parameter_format: :cobra)
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

    assert_match "#compdef dmt", (zsh_completion/"_dmt").read
  end
end
