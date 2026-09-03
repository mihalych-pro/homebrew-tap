# The binary is `d8`; the formula is named after the upstream project so that
# `brew search deckhouse` finds it and it does not squat the short name.
class DeckhouseCli < Formula
  desc "Command-line client for the Deckhouse Kubernetes Platform"
  homepage "https://deckhouse.io/"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.15/d8-v0.33.15-darwin-amd64.tar.gz"
      sha256 "f5d25f9beaece7acbfe7d8b2b817104734b5d106692db1b411e3a5a14c8d4bf2"
    end
    on_arm do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.15/d8-v0.33.15-darwin-arm64.tar.gz"
      sha256 "83ed9b2d272d1faf27239e255097bd2a599c41fc7ee47207607759505b4c01fc"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.15/d8-v0.33.15-linux-amd64.tar.gz"
      sha256 "8bc4289f5496f0072baea760fe53eb5d3bc340479d923597369532877bc4c49c"
    end
  end

  def install
    bin.install "bin/d8"
    generate_completions_from_executable(bin/"d8", shell_parameter_format: :cobra)
  end

  test do
    assert_match "d8 version v#{version}", shell_output("#{bin}/d8 --version")

    # `d8 k` is an embedded kubectl; the client-side version works without a cluster.
    assert_match "Client Version:", shell_output("#{bin}/d8 k version --client")

    assert_match "#compdef d8", (zsh_completion/"_d8").read
  end
end
