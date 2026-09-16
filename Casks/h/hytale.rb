cask "hytale" do
  version "2026.09.15-261d405"

  # `url` has to interpolate `version`: Cask::URL#unversioned? inspects the raw
  # source line and treats any url without `#{` as unversioned, which makes
  # `brew audit` demand `sha256 :no_check`. So this cask cannot be bumped by
  # substitution the way the formulas are, and scripts/update-formulas.rb hands
  # it to bump-cask-pr, which re-evaluates it per system to learn the new urls.
  on_macos do
    on_arm do
      sha256 "9e82c8293d756feb6387ba09c5deccc064258d91f0ce0388df56223f756edd01"
      url "https://launcher.hytale.com/builds/release/darwin/arm64/hytale-launcher-#{version}.dmg"
    end

    depends_on arch: :arm64

    app "Hytale Launcher.app"

    zap trash: [
      "~/Library/Caches/com.hypixel.hytale-launcher",
      "~/Library/Preferences/com.hypixel.hytale-launcher.plist",
      "~/Library/WebKit/com.hypixel.hytale-launcher",
    ]
  end
  on_linux do
    on_intel do
      sha256 "6c7e6254fd0494d4583a839d1b42bff2ae0bb430c834342a54362e2bae94c5fd"
      # The Linux archive holds a single bare executable, not an app bundle.
      url "https://launcher.hytale.com/builds/release/linux/amd64/hytale-launcher-#{version}.zip"
    end

    depends_on arch: :x86_64

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
