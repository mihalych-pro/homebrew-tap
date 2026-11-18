class WerfAT2 < Formula
  # Held in a constant rather than inlined below: with no top-level `url`,
  # FormulaAudit/LivecheckUrlSymbol compares a literal livecheck URL against
  # itself and autocorrects it to `url :stable`, pointing livecheck at a binary.
  #
  # The channel only ever names a 2.x release, which is what pins this formula
  # to the series.
  STABLE_CHANNEL = "https://tuf.werf.io/targets/channels/2/stable".freeze

  desc "Consistent delivery tool for Kubernetes"
  homepage "https://werf.io/"
  license "Apache-2.0"

  livecheck do
    url STABLE_CHANNEL
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :page_match
  end

  # Aliases/werf points at werf@3, the default since 3.x reached a stable
  # channel, so this one is not linked: both install `bin/werf`.
  keg_only :versioned_formula

  on_macos do
    on_intel do
      url "https://tuf.werf.io/targets/releases/2.84.1/darwin-amd64/bin/werf"
      sha256 "1f55f52e8205d5d8f6e963ff72c04bf202bff1c542f44edbd6f6ffca9dac224e"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/2.84.1/darwin-arm64/bin/werf"
      sha256 "cd0581676b0bd611e9ac24ee3b86fa9009ea56591f9959c62b1c162127fb3937"
    end
  end

  on_linux do
    on_intel do
      url "https://tuf.werf.io/targets/releases/2.84.1/linux-amd64/bin/werf"
      sha256 "a47a7d8a674c3c4ce12db6c765d67a2f772e078922ed7dc6327f41746f384f41"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/2.84.1/linux-arm64/bin/werf"
      sha256 "782a9a04f80e41b7ae893193b63265c3cf15ca64f4a7172fa9d38a15fcaf80b2"
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
