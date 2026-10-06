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
      url "https://tuf.werf.io/targets/releases/2.79.2/darwin-amd64/bin/werf"
      sha256 "4664a93e364a0c88bea75b08b58727e2c71ef54835c50ca3719eda45955f83ce"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/2.79.2/darwin-arm64/bin/werf"
      sha256 "79372c412fc49ae2093cfc106bf476f6b4fe0f2ea9900ca236da7e0d3e9bf0d0"
    end
  end

  on_linux do
    on_intel do
      url "https://tuf.werf.io/targets/releases/2.79.2/linux-amd64/bin/werf"
      sha256 "16feb4b5effa52ca653334d3c6ece1e0b9f1343cb0e72cb7e3f80a288d254e66"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/2.79.2/linux-arm64/bin/werf"
      sha256 "eac10514acfd292c76eb151a7f86985ad297fe49306e484d64338fc87d00c919"
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
