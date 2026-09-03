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
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.14/d8-v0.33.14-darwin-amd64.tar.gz"
      sha256 "7c2f22f93aa0b63afd0715e0543bbb54b12d9150cb27df77809081e467fe1d6c"
    end
    on_arm do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.14/d8-v0.33.14-darwin-arm64.tar.gz"
      sha256 "a34031d15d7d8178c6654397e26be86188ec51a9a7e4e760fb00fa51501a11c7"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.14/d8-v0.33.14-linux-amd64.tar.gz"
      sha256 "5d7ebb097970a1e71f23c683460fc50463229245306dda8f0e6b866d3d7ee043"
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
