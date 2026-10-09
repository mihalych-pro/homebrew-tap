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
  url "https://github.com/deckhouse/deckhouse-cli/archive/refs/tags/v0.34.5.tar.gz"
  sha256 "ef50bfd0fe73c4cebc6ce9f8b6ace2e09f3f52ff21ababbf6c7959fcc86a5254"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.34.5/d8-v0.34.5-darwin-amd64.tar.gz"
      sha256 "14a2086a053bf3eb68e6ab730dce41bc7bfa536790333cbb8ddacb6ca4d02b87"
    end
    on_arm do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.34.5/d8-v0.34.5-darwin-arm64.tar.gz"
      sha256 "24d3b914421d792b01edc8c4c086eed7c1a9b760e62e541b0d7464c4e2b5b0ff"
    end
  end

  on_linux do
    depends_on arch: :x86_64

    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.34.5/d8-v0.34.5-linux-amd64.tar.gz"
      sha256 "189b269f0912f2ba60fb01937bfe23db5a361e4a5839c68c1d514d7ff2af3611"
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
