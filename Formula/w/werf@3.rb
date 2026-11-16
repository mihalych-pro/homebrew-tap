class WerfAT3 < Formula
  # Held in a constant rather than inlined below: with no top-level `url`,
  # FormulaAudit/LivecheckUrlSymbol compares a literal livecheck URL against
  # itself and autocorrects it to `url :stable`, pointing livecheck at a binary.
  #
  # The channel only ever names a 3.x release, which is what pins this formula
  # to the series. Aliases/werf points here, which is why this one is linked
  # and werf@2 is keg-only.
  STABLE_CHANNEL = "https://tuf.werf.io/targets/channels/3/stable".freeze

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
      url "https://tuf.werf.io/targets/releases/3.12.1/darwin-amd64/bin/werf"
      sha256 "d31a9f7545eee81e17da22b472cff60c1b66c0ce0feb6eafe2c78130542bef4c"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/3.12.1/darwin-arm64/bin/werf"
      sha256 "98e71cbe244d6bba972320fb3ed6152de365cee580461edc4c4c866877460d56"
    end
  end

  on_linux do
    on_intel do
      url "https://tuf.werf.io/targets/releases/3.12.1/linux-amd64/bin/werf"
      sha256 "c88bcdf6320e738887fcafbefe060edc2d3db4fb5662c7668a51d3838ed6b6f7"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/3.12.1/linux-arm64/bin/werf"
      sha256 "e768cdd1f0251648064c5ecaec92b133cf590a7cbd47c21b73a4b692e602b9a0"
    end
  end

  # `werf config graph` in the test reports telemetry to telemetry.werf.io;
  # the test must not phone home. Install only runs `werf completion`, offline.
  deny_network_access! :test

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
