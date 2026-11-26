cask "hytale-launcher" do
  # Upstream lays its downloads out as `<os>/<arch>/hytale-launcher-<version>.<ext>`.
  arch arm: "arm64", intel: "amd64"

  version "2026.11.23-8717529"
  # Only the two builds that exist: macOS is published for arm64 alone and Linux
  # for amd64 alone. The Linux checksum is the one
  # https://launcher.hytale.com/version/release/launcher.json names -- the same
  # manifest the livecheck below reads; the macOS one is of the `.dmg`, which
  # that manifest does not list.
  #
  # The other two OS/arch pairs render a url upstream does not serve, and the
  # `depends_on arch:` in each block below is what refuses to install them.
  # macOS Intel still has to render one, because `brew tap` loads every cask
  # under every macOS version and arch, and one resolving to no url fails the
  # whole tap with "Missing URL".
  sha256 arm:          "1470347eaa3884334aba9de73e220b64b0bb7270f9bcbf0c90b6da7ee7ea5c07",
         x86_64_linux: "3b7cef6e3c77d62612bac34f125b288ac867ce8524c63786be58d11eb14db4cf"

  on_macos do
    # The `.dmg`, as homebrew-cask's own `hytale` uses, not the `.zip` the
    # manifest names: that archive carries a ~1.9 KB `HYTALE-UPDATE` header
    # ahead of the zip data, and brew refuses to unpack it (see on_linux).
    url "https://launcher.hytale.com/builds/release/darwin/#{arch}/hytale-launcher-#{version}.dmg"

    depends_on arch: :arm64

    # Its CFBundleIdentifier is com.hypixel.hytale-launcher, which the zap
    # paths below key off.
    app "Hytale Launcher.app"

    zap trash: [
      "~/Library/Caches/com.hypixel.hytale-launcher",
      "~/Library/Preferences/com.hypixel.hytale-launcher.plist",
      "~/Library/WebKit/com.hypixel.hytale-launcher",
    ]
  end
  on_linux do
    # Linux has no `.dmg` and nothing else brew can unpack: only this `.zip`
    # with the `HYTALE-UPDATE` header in front, and a `.flatpak` bundle. unzip
    # reads past the header but exits 1, "warnings, processing completed", and
    # brew's own zip strategy treats that as failure. So the archive is staged
    # as-is and unpacked by the step below, which accepts that exit status; a
    # real failure leaves no `hytale-launcher` behind and the `binary` stanza
    # fails the install. unzip is not among Homebrew's Linux requirements,
    # hence the formula and its exact path.
    url "https://launcher.hytale.com/builds/release/linux/#{arch}/hytale-launcher-#{version}.zip"

    depends_on arch: :x86_64
    depends_on formula: "unzip"
    container type: :naked

    # The archive holds a single bare executable, not an app bundle.
    binary "hytale-launcher"

    preflight_steps do
      run "opt/unzip/bin/unzip",
          base:         :homebrew_prefix,
          args:         ["-qq", "-o", "{{staged_path}}/hytale-launcher-{{version}}.zip", "-d", "{{staged_path}}"],
          must_succeed: false
      remove "hytale-launcher-{{version}}.zip"
    end

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
