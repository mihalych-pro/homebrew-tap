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
      url "https://tuf.werf.io/targets/releases/3.12.2/darwin-amd64/bin/werf"
      sha256 "c34055f108f6e477e4a4991a2108cc2ff892783bc646f7e592b3ef7b8090fd64"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/3.12.2/darwin-arm64/bin/werf"
      sha256 "9dca3af234220e27304031bd5bba9cd4263179942a8fc286867add5d92902097"
    end
  end

  on_linux do
    on_intel do
      url "https://tuf.werf.io/targets/releases/3.12.2/linux-amd64/bin/werf"
      sha256 "565a9508d5610551625008cd697a5a198535a9eab0f2b243e6e65c98700e615e"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/3.12.2/linux-arm64/bin/werf"
      sha256 "7800825285d98705bbd166f31ca8ea528a129729a3112618318bed6e34845557"
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
