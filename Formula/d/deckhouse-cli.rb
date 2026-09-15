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
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.17/d8-v0.33.17-darwin-amd64.tar.gz"
      sha256 "2afa9a3e5b03719f9e37669bd98a3714f70c59e14195da27427f6f99005abb98"
    end
    on_arm do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.17/d8-v0.33.17-darwin-arm64.tar.gz"
      sha256 "f58e92bf899e7de4d0b97bf6f30e2b28327dc681eb83297b76a824745b8dfc5d"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.17/d8-v0.33.17-linux-amd64.tar.gz"
      sha256 "eaff3360c7183bd27e58ce6d844c746e36ed19c32b5fdf87422f08b0f9f4c625"
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
