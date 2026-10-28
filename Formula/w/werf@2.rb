class WerfAT2 < Formula
  # Held in a constant rather than inlined below: with no top-level `url`,
  # FormulaAudit/LivecheckUrlSymbol compares a literal livecheck URL against
  # itself and autocorrects it to `url :stable`, pointing livecheck at a binary.
  #
  # The channel only ever names a 2.x release, which is what pins this formula
  # to the series. Aliases/werf points here, which is why this one is linked
  # and werf@3 is keg-only.
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
      url "https://tuf.werf.io/targets/releases/2.83.0/darwin-amd64/bin/werf"
      sha256 "94c8d48e7a35d2be29cbd70c21dc894a71c2026c70b32403683fd754ac169308"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/2.83.0/darwin-arm64/bin/werf"
      sha256 "bfc6edc3b7954429df416e3106e84a17f058437d1381fe90f655bccdc0c661bd"
    end
  end

  on_linux do
    on_intel do
      url "https://tuf.werf.io/targets/releases/2.83.0/linux-amd64/bin/werf"
      sha256 "e8f31e97d9c2bb8674d6bd11d6aaf4d393c2a7016fb413b3af6defd46d37fc9a"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/2.83.0/linux-arm64/bin/werf"
      sha256 "933f8abbeee702e12806d6f8a4d0403dcac61f00b20900910cbc11de644baddf"
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
