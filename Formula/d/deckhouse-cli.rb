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
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.21/d8-v0.33.21-darwin-amd64.tar.gz"
      sha256 "25ce6e5d9898a0a896cac6bdde6892de4f851d11d25e4246d2af7ae0ef58355a"
    end
    on_arm do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.21/d8-v0.33.21-darwin-arm64.tar.gz"
      sha256 "be591ad8b8d956a39905355ae2e80efb910b04a1b81eb919554da645eb8a4f37"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.21/d8-v0.33.21-linux-amd64.tar.gz"
      sha256 "4959d13f7d01523fb5c434d3207136d852ae59236fac511609de28b7da450db3"
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
