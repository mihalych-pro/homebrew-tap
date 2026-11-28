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
  url "https://github.com/deckhouse/deckhouse-cli/archive/refs/tags/v0.34.9.tar.gz"
  sha256 "a159c8b9c77c0433318057cb96eeeb4e8f5a3c871e698e4f607e50f5247a0d58"
  license "Apache-2.0"

  livecheck do
    url :stable
    # The latest GitHub release rather than tags, which livecheck would read by
    # default: the binaries are release assets, and a tag has preceded its
    # release by up to three days (v0.33.29).
    strategy :github_latest
  end

  on_macos do
    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.34.9/d8-v0.34.9-darwin-amd64.tar.gz"
      sha256 "30f52895e1c00f554e39f60b60e769a38479ddcaf6984667b11e1d3d11d7bda3"
    end
    on_arm do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.34.9/d8-v0.34.9-darwin-arm64.tar.gz"
      sha256 "2bd4f6ba209007f2084e4716f07f76ddcec2df8d41901d718c04ff4c541def8a"
    end
  end

  on_linux do
    depends_on arch: :x86_64

    on_intel do
      url "https://github.com/deckhouse/deckhouse-cli/releases/download/v0.34.9/d8-v0.34.9-linux-amd64.tar.gz"
      sha256 "64e3324a1fcc3e088f6dd22754e05f65c7753bac59baab0c0b9e286871350f94"
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
