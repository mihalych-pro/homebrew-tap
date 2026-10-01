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
  url "https://github.com/deckhouse/deckhouse-cli/archive/refs/tags/v0.33.23.tar.gz"
  sha256 "0de3f971bd53d680f47790eec278670ea8c9b8a09f56f7528766fad654ff16b4"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.23/d8-v0.33.23-darwin-amd64.tar.gz"
      sha256 "a8d604be831f7315ab00ac20bc7c9d4dc1134d0e9acbd4ebcc718a6256d41762"
    end
    on_arm do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.23/d8-v0.33.23-darwin-arm64.tar.gz"
      sha256 "67a1b165a5083c18981fb3713d8e182fd134a96715d1245d3e2af58c5efa6c63"
    end
  end

  on_linux do
    depends_on arch: :x86_64

    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.33.23/d8-v0.33.23-linux-amd64.tar.gz"
      sha256 "c050a9472f45cc9f0a117d64f1c55594c8d99dda264272cbd9f83c97694593ef"
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
