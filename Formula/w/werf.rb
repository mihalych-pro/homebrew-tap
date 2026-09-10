class Werf < Formula
  # Held in a constant rather than inlined below: with no top-level `url`,
  # FormulaAudit/LivecheckUrlSymbol compares a literal livecheck URL against
  # itself and autocorrects it to `url :stable`, pointing livecheck at a binary.
  #
  # GitHub tags run ahead of what is actually released -- 3.x is tagged but has
  # no trdl channel yet, so 2/stable is the current stable werf. Bump the `2`
  # once upstream promotes a new major series.
  STABLE_CHANNEL = "https://tuf.werf.io/targets/channels/2/stable".freeze

  desc "Consistent delivery tool for Kubernetes"
  homepage "https://werf.io/"
  license "Apache-2.0"

  livecheck do
    url STABLE_CHANNEL
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :page_match
  end

  on_macos do
    on_intel do
      url "https://tuf.werf.io/targets/releases/2.76.0/darwin-amd64/bin/werf"
      sha256 "e7236a94f0254896cf5ccb65b1f94931260b57592f9b624c1e786f4e1700cd7c"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/2.76.0/darwin-arm64/bin/werf"
      sha256 "d761f43378e72ab82b05c6dcb394bf0ea282ce3396c91807e04a18f8abb4577d"
    end
  end

  on_linux do
    on_intel do
      url "https://tuf.werf.io/targets/releases/2.76.0/linux-amd64/bin/werf"
      sha256 "078511459d0ba81111c629c3d4ecb24dc41a3736736f515084aef38182344202"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/2.76.0/linux-arm64/bin/werf"
      sha256 "6286687d6f4a97f5cd37d10c0415cc0810cd5dde44ce94263995f0ad36dd08d3"
    end
  end

  def install
    bin.install "werf"
    # The TUF repository serves a bare binary, so the executable bit is not
    # preserved by the download; Cleaner only keeps a bit that is already set.
    chmod 0555, bin/"werf"

    # werf takes the shell as `--shell=zsh`; with the cobra format it silently
    # returns the bash script for every shell.
    generate_completions_from_executable(bin/"werf", "completion", shell_parameter_format: :arg)
  end

  test do
    werf_config = testpath/"werf.yaml"
    werf_config.write <<~YAML
      configVersion: 1
      project: quickstart-application
      ---
      image: vote
      dockerfile: Dockerfile
      context: vote
      ---
      image: result
      dockerfile: Dockerfile
      context: result
      ---
      image: worker
      dockerfile: Dockerfile
      context: worker
    YAML

    output = <<~YAML
      - image: result
      - image: vote
      - image: worker
    YAML

    system "git", "init"
    system "git", "add", werf_config
    system "git", "commit", "-m", "Initial commit"

    assert_equal output,
      shell_output("#{bin}/werf config graph").lines.sort.join

    assert_match version.to_s, shell_output("#{bin}/werf version")

    assert_match "#compdef werf", (zsh_completion/"_werf").read
  end
end
