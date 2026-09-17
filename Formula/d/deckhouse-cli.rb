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
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.19/d8-v0.33.19-darwin-amd64.tar.gz"
      sha256 "10664873b91355d9fae0c68a73b40b2197f7dfc14f39ec357f31ddbe5976b95a"
    end
    on_arm do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.19/d8-v0.33.19-darwin-arm64.tar.gz"
      sha256 "2ed887470cd9207c141cbfcc8c40995025faea7761d57c6b49f373c6ac5f062a"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.19/d8-v0.33.19-linux-amd64.tar.gz"
      sha256 "6d698d851e2356ee1123a028de689fdf135d8ffc76b3c61ae8b19e2fd851c784"
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
