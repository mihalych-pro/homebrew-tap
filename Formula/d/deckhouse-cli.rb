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
  url "https://github.com/deckhouse/deckhouse-cli/archive/refs/tags/v0.34.3.tar.gz"
  sha256 "29c9e452ffe696a4ba449601e2d09db38e849dc40d4e81e4f50649ad5a7a8fb4"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.34.3/d8-v0.34.3-darwin-amd64.tar.gz"
      sha256 "79ca40912d0b63ef84a5cabf878ee7f4403b9b7db8b7f9c9365264a578344c52"
    end
    on_arm do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.34.3/d8-v0.34.3-darwin-arm64.tar.gz"
      sha256 "9de895fcac5239fbaa7f0dcba1d6e3c4491d4a22406f4bc8d68013bff034b09d"
    end
  end

  on_linux do
    depends_on arch: :x86_64

    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.34.3/d8-v0.34.3-linux-amd64.tar.gz"
      sha256 "236ceaceac48d2c50c00e2479de451d245595b25d4ae24094679c82f677955b9"
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
