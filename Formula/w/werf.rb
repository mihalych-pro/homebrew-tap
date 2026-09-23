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
      url "https://tuf.werf.io/targets/releases/2.77.2/darwin-amd64/bin/werf"
      sha256 "6176bb1a3d53f166214f4ded5f6f23b95737d5fdb85cc98d033b5f048fedea3e"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/2.77.2/darwin-arm64/bin/werf"
      sha256 "3f90220dee768bec771345dd85477dfee47a6c72576ee6f1370424ec0e33d80c"
    end
  end

  on_linux do
    on_intel do
      url "https://tuf.werf.io/targets/releases/2.77.2/linux-amd64/bin/werf"
      sha256 "b7fded3e08a44059a04864dfd086d1628b520fafa7f6945c86112a687cf61e42"
    end
    on_arm do
      url "https://tuf.werf.io/targets/releases/2.77.2/linux-arm64/bin/werf"
      sha256 "5ba2bbb7fa5ef4370723011cc5ce72c4a2c244a5f8865080e607078c487c1da5"
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
