# Agent Instructions

Personal Homebrew tap, `mihalych-pro/tap`. Formulae live in
`Formula/<first-letter>/<name>.rb`, casks in `Casks/<first-letter>/<token>.rb`.
[FORMULAE.md](FORMULAE.md) and [CASKS.md](CASKS.md) are **generated** — never
edit them by hand.

Every package here ships **prebuilt binaries**, one `url`/`sha256` pair per
platform. Nothing is built from source.

## Local setup

`brew` only sees the tap through a symlink, and loading its files runs their
Ruby, so the tap has to be trusted once:

```sh
taps="$(brew --repository)/Library/Taps/mihalych-pro"
mkdir -p "$taps" && ln -sfn "$PWD" "$taps/homebrew-tap"
brew trust --tap mihalych-pro/tap
```

Copying instead of symlinking breaks everything downstream: `brew` would edit
files that never reach your commit.

## Entry points

```sh
task check                 # what is outdated (formulae and casks, separately)
task update                # bump everything outdated
task update -- werf@2      # …or just one, --dry-run and --set VERSION also work
task docs                  # regenerate FORMULAE.md / CASKS.md
task audit                 # brew style + brew audit --strict --online + readall
task audit -- werf@2       # …or just one package
task fix                   # brew style --fix
task test                  # install and run the test block of each formula
```

Scripts run under Homebrew's Ruby. Flags need `--` or `brew ruby` eats them:
`brew ruby scripts/update-formulas.rb -- --dry-run`. They load packages by full
name, `mihalych-pro/tap/<name>`: since Homebrew 7.0.13 `Formulary.factory` and
`Cask::CaskLoader.load` refuse a file path, and the `from_path` loaders that
still take one are internal to brew.

## Constraints that are easy to break

**Do not replace `scripts/update-formulas.rb` with `brew bump-formula-pr`.**
It cannot see a `url` nested in `on_macos`/`on_linux` — `Utils::AST::FormulaAST`
inspects only direct children of the class body — and dies with
`Could not find 'url' stanza!`. Verified repeatedly. `bump-cask-pr`, which the
script hands some casks (below), was observed leaving one platform's checksum
wrong in a cask with a `url`/`sha256` pair inside each `on_*` block; with every
`sha256` at top level, as the cops require, it rewrites them all correctly --
verified on `kurlo` (3.1.3 to 3.1.2 and back) and `hytale-launcher`.

**Formula urls spell the version out and carry no `version` stanza.** Adding one
makes `brew audit` report it as "redundant with version scanned from URL".

**Cask urls must interpolate `#{version}`.** `Cask::URL#unversioned?` reads the
raw source line, strips `#{arch}`, and calls any url still without `#{`
unversioned, which makes audit demand `sha256 :no_check`. A url that
interpolates *only* `version` is rendered by the bump script itself;
`hytale-launcher` and `kurlo` interpolate `#{arch}` too, so they fall through to `bump-cask-pr`,
which re-evaluates the cask once per system. That is the path homebrew-cask's
own per-platform casks take.

**Run `task audit` after `task fix`.** `brew style --fix` has reordered
`Casks/h/hytale-launcher.rb` into a state its own `Cask/StanzaOrder` cop rejects. The
order that passes is: the `arch`/`os` helpers, `version`, `sha256`, the
`on_macos`/`on_linux` blocks, then a top-level `url` if there is one,
`name`/`desc`/`homepage`, `livecheck`, `auto_updates` -- the layout
homebrew-cask's `recordly` uses.

**`task audit` runs `brew audit --online`.** Only online does it download and
unpack each artifact and compare a cask's `depends_on macos:` with the minimum
the bundle declares -- the artifact's `LSMinimumSystemVersion`, never the
vendor's stated requirement. Offline it passed a `hytale` whose archive brew
could not unpack, so nothing installed. It checks the current platform only:
Linux in CI, so a macOS-only change also needs a local `task audit`.

**A `livecheck` block with a literal url needs the frozen constant.** With no
top-level `url`, `FormulaAudit/LivecheckUrlSymbol` compares that url against
itself and "corrects" it to `url :stable`, which points livecheck at a binary.
Assign it to a constant (see `Formula/w/werf@2.rb`) and reference that.

**A bare binary needs `chmod 0555` in `install`.** Homebrew's `Cleaner` only
keeps an executable bit that is already set, and a downloaded file has 0644.

**Versions are compared as numbers**: `2.01.3` equals `2.1.3`, so a typo'd
leading zero reads as "up to date" forever while the url 404s.

**Every package must load on every OS/arch pair, including ones upstream does
not build for.** `brew tap` calls `Readall.valid_tap?` over
`OnSystem::ALL_OS_ARCH_COMBINATIONS`, and one failure fails the tap as a whole
with `Cannot tap ...: invalid syntax in tap!`:

- A **formula** must resolve a url everywhere; with none on, say, linux-arm64
  it raises `formula requires at least a URL`. Verified: neither
  `depends_on arch:` nor `disable!` excuses a missing url -- only a url that
  resolves does. So it carries a top-level `url`/`sha256` pointing at the
  *source* of the same tag, which the `on_macos`/`on_linux` blocks override
  wherever a binary exists, plus `depends_on arch:` stating the restriction.
  The source is a fallback that is never fetched: the requirement fails first.
  homebrew-core has no exact precedent -- a core formula builds the source url
  it declares -- but the shape is valid and passes audit. Only `deckhouse-cli`
  needs it; `deckhouse-module-tool`, `flant-flint`, `onion-gen`, `werf@2` and
  `werf@3` publish all four binaries.
- A **cask** is checked per OS. On macOS every version and arch must resolve a
  url (`Missing URL` otherwise), except versions its `depends_on macos:`
  excludes. On Linux the check is that a `sha256` matches, and a
  `depends_on arch:` excluding that arch excuses its absence. List a `sha256`
  only for the platforms that exist, at top level with per-platform keys
  (`arm:`, `intel:`, `x86_64_linux:`, ...): `Cask/OnSystemConditionals`
  forbids one inside `on_macos`/`on_linux`. The combinations upstream does not
  publish render a url that 404s and carry no checksum; `depends_on arch:` in
  the matching `on_macos`/`on_linux` block is what refuses to install them.
  The url itself takes one of two cop-clean layouts:
  - **one top-level url** built from `arch`/`os` helpers, when the artifacts
    differ only in those -- homebrew-cask's `recordly`;
  - **one url per `on_macos`/`on_linux` block**, when the OSes ship different
    formats or names -- `hytale-launcher` (`.dmg` / `.zip`), `kurlo` (a universal
    `.app.zip` / an `AppImage`), homebrew-cask's `jan`. `Cask/NoOverrides`
    forbids mixing the two: a top-level url that a block overrides.

Never silence the check by repeating another architecture's artifact under
`on_arm`/`on_intel`: the package would then advertise a build that does not
exist, which is what the url pattern above avoids.

`brew style` catches none of this and neither does `brew audit`. `task readall`
(part of `task audit`) runs the same check `brew tap` does. After touching a
package's url or `sha256` layout, also prove the bump script can rewrite it --
the shapes that satisfy `Readall` are not all shapes it can. For a package the
script renders itself, `task update -- <name> --set <any newer version>
--dry-run` shows the result. A cask it hands to `bump-cask-pr` is not run by
`--dry-run`, so bump it for real to an older release and back, compare every
`sha256` with upstream's published checksums, and confirm the file comes back
byte-identical.

The failure is invisible locally while the tap is symlinked, because `brew tap`
never runs on it -- and invisible on a machine that has not trusted the tap,
because untrusted files are skipped before verification. It surfaces on a fresh
machine whose `trust.json` arrived with the dotfiles.

**There are no bottles.** Every formula already downloads upstream's binary,
so a bottle would only repackage it; the bottle workflows `brew tap-new`
generates are deliberately absent.

**Livecheck reads GitHub's latest release, not tags.** homebrew-core prefers the
`Git` strategy because its formulae download the tag's source archive, which
exists the moment the tag does. Here the download is a release asset, attached
later: `deckhouse-cli` has tagged up to three days before releasing (v0.33.29),
`dmt` up to a day (v0.2.8). `strategy :github_latest` keeps the bump from
reaching for a binary that is not there yet. Even a published `dmt` release has
gained its assets 14-60 minutes later; a bump caught in that window fails for
that one package and succeeds on the next run.

**A cask downloads into quarantine, with no opt-out** -- brew removed
`--no-quarantine`. An app that is not notarised (`kurlo` is ad-hoc signed) is
blocked by Gatekeeper on first launch, so its cask carries `caveats` telling the
user how to allow it. A cask cannot depend on system packages either; state
those in `caveats` too, as `kurlo` does for WebKitGTK and FUSE on Linux.

**A bare name resolves to `homebrew/core` or `homebrew/cask` first.** Check
`brew info --json=v2 --formula <name>` (or `--cask <token>`) before naming
anything: it reports the tap a name actually resolves to. `flant-flint` is named
that way because core's `flint` is an unrelated library — and note core's
`werf` (2.x, from source) shadows the bare name, so only
`mihalych-pro/tap/werf` reaches the alias below. Cask tokens must be globally
unique (`docs/How-to-Create-and-Maintain-a-Tap.md`): this tap's Hytale cask is
`hytale-launcher` because homebrew-cask already has `hytale`, and
`cask_renames.json` carries installs made under the old token across.

**werf is two versioned formulae plus an alias, as core does for `openssl`.**
`Formula/w/werf@2.rb` (`WerfAT2`) and `Formula/w/werf@3.rb` (`WerfAT3`) are
the real formulae; each livecheck reads its own series' trdl channel,
`channels/<N>/stable`. `Aliases/werf` is a symlink to the default, `werf@3`
since 3.x reached its stable channel; that one is linked while the other
carries `keg_only :versioned_formula`, since both install `bin/werf`. There is
no `Formula/w/werf.rb`, and none must be added: the alias wins name resolution,
so such a file would be unreachable. `brew audit` does not notice, but
`task readall` and `brew tap` reject it as "Formula duplicating alias".

To make a new series N the default, once upstream publishes
`channels/N/stable`:

1. `ln -sfn ../Formula/w/werf@N.rb Aliases/werf`
2. Move `keg_only :versioned_formula` from `werf@N.rb` to the previous default.
3. Point `werf@N`'s livecheck at `channels/N/stable` (`:page_match`, the
   constant pattern above).
4. `task docs`, `task audit`.
5. Tell users who trust per formula to run
   `brew trust --formula mihalych-pro/tap/werf@N`: trust is granted to the
   canonical name, and an existing trust does not follow the alias to its new
   target (`docs/Tap-Trust.md`).

Installs made through `mihalych-pro/tap/werf` record the alias, so
`brew upgrade` follows it to the new target and unlinks the old keg
(`Formula#latest_formula`, `follow_installed_alias`). Installs made by an
explicit `werf@<old>` stay on that series, which is now keg-only: `werf` leaves
their `PATH` until they run it from `$(brew --prefix werf@<old>)/bin`.

Do not add `werf` to `formula_renames.json`: `brew audit --tap` rejects a name
that is both an alias and a rename, and it is not needed -- `possible_names`
includes aliases, so an old `Cellar/werf` keg from this tap already counts as an
installed `werf@2`. The same rule means a machine with core's `werf` installed
must uninstall it before installing the tap's alias target.

## Test blocks

A `test do` block must actually exercise the binary: at least one assertion
beyond `--version` or `--help`. Existing formulae show the pattern — `d8 k
version --client`, `dmt lint` on a throwaway module, `werf config graph`.

Declare `deny_network_access!` only for a phase whose commands actually reach
the network: `werf config graph` reports telemetry to `telemetry.werf.io`, so
`werf@2` and `werf@3` deny it in `:test`; nothing else here connects anywhere.
To check a formula, run its `install` and `test` commands under `sandbox-exec`
with a profile denying `network-outbound (remote ip)`, then read the kernel's
`Sandbox: <process> deny(1) network-outbound` lines with `/usr/bin/log show`.

## CI

- `bump-formulas.yml` — every 6h, one pull request per outdated package, each
  carrying its own package file and its own row in the listings, labelled
  `automated-bump`. Commit subject is `<name> <version>`.
- `merge-automated-prs.yml` — every 6h at :33, squash-merges labelled pull
  requests older than 24h.

Merging one bump conflicts the others on the listing files, because git cannot
auto-merge adjacent table rows. This is expected and self-healing: the merge
workflow skips the conflicted pull request and re-dispatches the bump workflow,
which rebuilds each branch from the new `main`.

Both run on `ubuntu-latest`, x86_64. Every package loads on linux-arm64 too
(thanks to `deckhouse-cli`'s source fallback), but only x86_64 has a real Linux
artifact for every package -- `deckhouse-cli` and the casks publish none for
arm64 -- so that is where `task audit --online` checks them all.

## Reference

- [Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Cask Cookbook](https://docs.brew.sh/Cask-Cookbook)
- [`brew` manpage](https://docs.brew.sh/Manpage) or `man brew`
