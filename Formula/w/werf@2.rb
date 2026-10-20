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
      url "https://tuf.werf.io/targets/releases/2.80.2/darwin-amd64/bin/werf"
      sha256 "e8f026fe7f958db26929b515287f327fae46945669b24abaf009d2190f08507d"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/2.80.2/darwin-arm64/bin/werf"
      sha256 "d1ad1a35dd58f9f0c9ef602263a8a3ac132636f6affd8254508c8aa31e49345d"
    end
  end

  on_linux do
    on_intel do
      url "https://tuf.werf.io/targets/releases/2.80.2/linux-amd64/bin/werf"
      sha256 "96516fb562135d4ceb1fcedde5635a5cdab0589991728b28984909dd392f9d2b"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/2.80.2/linux-arm64/bin/werf"
      sha256 "6c13e931f596214ff5223aedf5427d82f3a78b37bdb219346261bc6676bacc41"
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
