cask "hytale" do
  # Upstream lays its downloads out as `<os>/<arch>/hytale-launcher-<version>.zip`,
  # so the same interpolation homebrew-cask uses for a cask with one build per
  # platform (see `recordly`) renders every url from these two helpers.
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "2026.09.21-909ac0c"
  # Only the two builds that exist: macOS is published for arm64 alone and Linux
  # for amd64 alone. Both checksums are of the archives that
  # https://launcher.hytale.com/version/release/launcher.json names -- the same
  # manifest the livecheck below reads. Upstream also serves an undocumented
  # darwin `.dmg`, holding the same app under a prettier bundle name; it is
  # deliberately unused, being absent from that manifest.
  #
  # The other two OS/arch pairs render a url upstream does not serve, and the
  # `depends_on arch:` in each block below is what refuses to install them --
  # `recordly` states its single Linux build the same way. They still have to
  # render something, because `brew tap` loads every cask under every OS/arch
  # pair and one resolving to no url fails the whole tap with "Missing URL".
  sha256 arm:          "6ce97db29b94aa1eef53eba7ccd41fa0c83bdcd0389ea3e72e69d9cb3dbe445e",
         x86_64_linux: "59915a56b933ba135241d25617c279d0fb1a49b8f856195dc7fc1c4368f8b55b"

  on_macos do
    depends_on arch: :arm64

    # The bundle inside the archive is `hytale-launcher.app`; its
    # CFBundleName is "Hytale Launcher" and its identifier
    # com.hypixel.hytale-launcher, which the zap paths below key off.
    app "hytale-launcher.app"

    zap trash: [
      "~/Library/Caches/com.hypixel.hytale-launcher",
      "~/Library/Preferences/com.hypixel.hytale-launcher.plist",
      "~/Library/WebKit/com.hypixel.hytale-launcher",
    ]
  end
  on_linux do
    depends_on arch: :x86_64

    # The Linux archive holds a single bare executable, not an app bundle.
    binary "hytale-launcher"

    # The Linux build stores state under the XDG base directories rather than
    # ~/Library. The `hytale-launcher` subdirectory is inferred from the
    # binary's own strings (it references XDG_CONFIG_HOME, XDG_DATA_HOME and
    # XDG_CACHE_HOME alongside a `hytale-launcher/` path fragment) and has not
    # been confirmed by running it; a zap path that does not exist is skipped.
    zap trash: [
      "~/.cache/hytale-launcher",
      "~/.config/hytale-launcher",
      "~/.local/share/hytale-launcher",
    ]
  end

  # The url interpolates more than `version`, so scripts/update-formulas.rb
  # cannot render the next one by substitution and hands the cask to
  # bump-cask-pr, which re-evaluates it once per system to learn the new urls.
  url "https://launcher.hytale.com/builds/release/#{os}/#{arch}/hytale-launcher-#{version}.zip"
  name "Hytale"
  desc "Official Hytale Launcher"
  homepage "https://hytale.com/"

  livecheck do
    url "https://launcher.hytale.com/version/release/launcher.json"
    strategy :json do |json|
      json["version"]
    end
  end

  auto_updates true
end
