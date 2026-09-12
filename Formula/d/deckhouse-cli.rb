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
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.16/d8-v0.33.16-darwin-amd64.tar.gz"
      sha256 "66feb2bc327aaa47000db734d4f90f4e0822c3ad7bf427b0b1803aa190dec9e9"
    end
    on_arm do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.16/d8-v0.33.16-darwin-arm64.tar.gz"
      sha256 "3c1dc33acbb5c128dc2453ecfc15f6daa86d4c67bf2272ed185eb6235b5f6008"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.16/d8-v0.33.16-linux-amd64.tar.gz"
      sha256 "4f361bfe85a194d86b1f20a4e644cdddc0be36f4ccf013bd0dccfc9aefe0f2bb"
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
