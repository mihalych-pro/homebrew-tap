cask "hytale" do
  version "2026.09.08-e1d69dd"

  # `url` has to interpolate `version`: Cask::URL#unversioned? inspects the raw
  # source line and treats any url without `#{` as unversioned, which makes
  # `brew audit` demand `sha256 :no_check`. So this cask cannot be bumped by
  # substitution the way the formulas are, and scripts/update-formulas.rb hands
  # it to bump-cask-pr, which re-evaluates it per system to learn the new urls.
  on_macos do
    on_arm do
      sha256 "b641f5d1b480f7be2639715d5199d53fc7742af9885df558a15406d94d79f5c4"
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
      sha256 "211df76d9dc94fe2e7188a2b0cef7b0b8e75dc540d6eb283e4338240141cf1e8"
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
