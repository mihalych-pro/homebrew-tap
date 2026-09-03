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
      url "https://tuf.werf.io/targets/releases/2.75.3/darwin-amd64/bin/werf"
      sha256 "6cb6624ee3dfdeddaa4edcc4ca8f7363bfd62467caeac0ea8b0638189befb9e9"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/2.75.3/darwin-arm64/bin/werf"
      sha256 "2c7c71284fdaf236d57070080d81e3a007e7a5dbb4345a653e7613347ec00f8f"
    end
  end

  on_linux do
    on_intel do
      url "https://tuf.werf.io/targets/releases/2.75.3/linux-amd64/bin/werf"
      sha256 "40d6c7846c43f27928fb180d44fb35297d059e6107d9d29ad70170edaa7d223c"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/2.75.3/linux-arm64/bin/werf"
      sha256 "07f657708d01160d0cdd1f21c5ac4af3791056bf662b8be6dd0f44c9028d90df"
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
