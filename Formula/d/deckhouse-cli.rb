# The binary is `d8`; the formula is named after the upstream project so that
# `brew search deckhouse` finds it and it does not squat the short name.
class DeckhouseCli < Formula
  desc "Command-line client for the Deckhouse Kubernetes Platform"
  homepage "https://deckhouse.io/"
  # Fallback spec, reached on linux-arm64 and nowhere else: every other platform
  # is overridden by an `on_macos`/`on_linux` block below. Upstream publishes no
  # linux-arm64 binary, and the `depends_on arch: :x86_64` below is what refuses
  # to install there -- but a spec still has to resolve, because `brew tap` loads
  # every formula under every OS/arch pair (`Readall.valid_tap?`) and one that
  # resolves to no url raises "formula requires at least a URL", failing the
  # whole tap. Neither `depends_on arch:` nor `disable!` excuses a missing url.
  # Pointing it at the source of the same tag is core's own shape (see
  # `graalvm`) and keeps the formula from claiming an arm64 binary that does not
  # exist. Nothing is ever fetched from it: the requirement fails first.
  url "https://github.com/deckhouse/deckhouse-cli/archive/refs/tags/v0.34.7.tar.gz"
  sha256 "19083ed90d482d648a3470bdd5908feeeec123ded3b580c9f34abc68812829b8"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.34.7/d8-v0.34.7-darwin-amd64.tar.gz"
      sha256 "2612d6c114b5486f435b01a9b74f9f9747dc28cd80337dcd12f095f3681fe554"
    end
    on_arm do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.34.7/d8-v0.34.7-darwin-arm64.tar.gz"
      sha256 "7068dcbe85800d0291c2f66022ea1921c802d76eae1dc3402689d061020cfd95"
    end
  end

  on_linux do
    depends_on arch: :x86_64

    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.34.7/d8-v0.34.7-linux-amd64.tar.gz"
      sha256 "a3c53f13fd7ca03f24b6f0205671db75e2273ab2dad04b87778a13deda431517"
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
