cask "kurlo" do
  # Only the Linux url is spelled with this helper: upstream names its AppImage
  # `kurlo-<version>-linux-<arch>.AppImage`, and `arm64` renders a url that is
  # not served (see below). macOS is one universal build with no arch in its name.
  arch arm: "arm64", intel: "amd64"

  version "3.2.0"
  # Both checksums are those of SHA256SUMS.txt in the release. macOS ships a
  # single universal build, so arm and Intel share one. Linux is published for
  # amd64 alone: the arm64 AppImage the Linux url renders is not served and has
  # no checksum, and the `depends_on arch:` in `on_linux` is what refuses it.
  # It still has to render something, because `brew tap` loads every cask under
  # every OS/arch pair and one resolving to no url fails the whole tap with
  # "Missing URL".
  sha256 arm:          "87befa5dfb19b29e97eda54a8572b4a41a50d2cc60fab37fa3f9f9e7969b81c6",
         intel:        "87befa5dfb19b29e97eda54a8572b4a41a50d2cc60fab37fa3f9f9e7969b81c6",
         x86_64_linux: "c27b77949c1fa1fc16f95b139c2f770e32371c1ebf89754b1c8607db06aa0ced"

  on_macos do
    # The bundle zipped for the in-app updater (`darwin-universal-app` in
    # latest.json) rather than the `.dmg`: the same app, without mounting an image.
    url "https://github.com/stormhop/kurlo/releases/download/v#{version}/kurlo-darwin-universal.app.zip"

    # Upstream supports macOS 15 Sequoia and later, but the bundle declares
    # LSMinimumSystemVersion 12.0 (it still starts on 12-14, untested), and
    # `brew audit --online` requires `depends_on` to match the bundle.
    depends_on macos: :monterey

    app "Kurlo.app"

    # The store is `os.UserConfigDir()/Kurlo`, holding preferences, logs and the
    # encrypted secrets. Workspaces kept in `~/Documents/Kurlo` are not touched.
    zap trash: "~/Library/Application Support/Kurlo"

    # The bundle is ad-hoc signed, with no Team ID and no notarisation ticket,
    # and brew quarantines every cask download, with no opt-out since
    # `--no-quarantine` was removed.
    caveats <<~EOS
      Kurlo is not notarised, so Gatekeeper blocks its first launch. Allow it
      once under System Settings > Privacy & Security > Open Anyway, or clear
      the quarantine flag:
        xattr -dr com.apple.quarantine #{appdir}/Kurlo.app
    EOS
  end
  on_linux do
    url "https://github.com/stormhop/kurlo/releases/download/v#{version}/kurlo-#{version}-linux-#{arch}.AppImage"

    depends_on arch: :x86_64

    # A version-less target: the in-app updater overwrites the file in place,
    # and `brew audit` rejects a versioned name for that reason.
    app_image "kurlo-#{version}-linux-#{arch}.AppImage", target: "kurlo.AppImage"

    zap trash: "~/.config/Kurlo"

    # The AppImage holds nothing but the executable: it links against the
    # system's WebKitGTK 4.1 and GTK 3, and its classic runtime dlopens
    # libfuse.so.2 to mount itself. A cask cannot depend on system packages.
    caveats <<~EOS
      Kurlo needs WebKitGTK 4.1, GTK 3 and FUSE 2 from your distribution:
        Debian/Ubuntu: sudo apt install libwebkit2gtk-4.1-0 libfuse2
                       (libfuse2t64 on Ubuntu 24.04 and later)
        Fedora:        sudo dnf install webkit2gtk4.1 fuse-libs
      Without FUSE, run it as: #{appdir}/kurlo.AppImage --appimage-extract-and-run
    EOS
  end

  name "Kurlo"
  desc "Open-source API client with an agent inside"
  homepage "https://kurlo.dev/"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
end
