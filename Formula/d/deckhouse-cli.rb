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
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.22/d8-v0.33.22-darwin-amd64.tar.gz"
      sha256 "56ef249f3108b9f3b71bb15dfabec0bb730aceae9fd6a0149e2cd20d50c8fa93"
    end
    on_arm do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.22/d8-v0.33.22-darwin-arm64.tar.gz"
      sha256 "3880ca32184a08d42de8659a241b3593bb193e690f5ddc106dfc5aee53dc01c6"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.22/d8-v0.33.22-linux-amd64.tar.gz"
      sha256 "e7ebf0a6cbf446f44f65313391d9f11ab35e3a076eb819ac18d070544ff8529e"
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
