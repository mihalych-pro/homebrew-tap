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
task audit                 # brew style + brew audit --strict over the tap
task audit -- werf@2       # …or just one package
task fix                   # brew style --fix
task test                  # install and run the test block of each formula
```

Scripts run under Homebrew's Ruby. Flags need `--` or `brew ruby` eats them:
`brew ruby scripts/update-formulas.rb -- --dry-run`.

## Constraints that are easy to break

**Do not replace `scripts/update-formulas.rb` with `brew bump-formula-pr`.**
It cannot see a `url` nested in `on_macos`/`on_linux` — `Utils::AST::FormulaAST`
inspects only direct children of the class body — and dies with
`Could not find 'url' stanza!`. Verified repeatedly. `bump-cask-pr` is worse for
a cask with per-OS blocks: it has been observed leaving one platform's checksum
wrong and not repairing it on later runs.

**Formula urls spell the version out and carry no `version` stanza.** Adding one
makes `brew audit` report it as "redundant with version scanned from URL".

**Cask urls must interpolate `#{version}`.** `Cask::URL#unversioned?` reads the
raw source line and calls any url without `#{` unversioned, which makes audit
demand `sha256 :no_check`. A url that interpolates *only* `version` is rendered
by the bump script itself; `hytale` interpolates `#{os}`/`#{arch}` too, so it
falls through to `bump-cask-pr`, which re-evaluates the cask once per system.
That is the path homebrew-cask's own per-platform casks take.

**Run `task audit` after `task fix`.** `brew style --fix` has reordered
`Casks/h/hytale.rb` into a state its own `Cask/StanzaOrder` cop rejects. The
order that passes is: the `arch`/`os` helpers, `version`, `sha256`, the
`on_macos`/`on_linux` blocks, then `url`, `name`/`desc`/`homepage`,
`livecheck`, `auto_updates` -- the layout homebrew-cask's `recordly` uses.

**A `livecheck` block with a literal url needs the frozen constant.** With no
top-level `url`, `FormulaAudit/LivecheckUrlSymbol` compares that url against
itself and "corrects" it to `url :stable`, which points livecheck at a binary.
Assign it to a constant (see `Formula/w/werf@2.rb`) and reference that.

**A bare binary needs `chmod 0555` in `install`.** Homebrew's `Cleaner` only
keeps an executable bit that is already set, and a downloaded file has 0644.

**Versions are compared as numbers**: `2.01.3` equals `2.1.3`, so a typo'd
leading zero reads as "up to date" forever while the url 404s.

**Every OS/arch pair must resolve to a url, including ones upstream does not
build for.** `brew tap` calls `Readall.valid_tap?` over
`OnSystem::ALL_OS_ARCH_COMBINATIONS`. A formula resolving to no url on, say,
linux-arm64 raises `formula requires at least a URL`; a cask resolving to none
on macOS Intel raises `Missing URL`; either fails the tap as a whole with
`Cannot tap ...: invalid syntax in tap!`. Verified: neither `depends_on arch:`
nor `disable!` excuses a missing url -- only a url that resolves does. Follow
homebrew-core and homebrew-cask:

- A **formula** carries a top-level `url`/`sha256` pointing at the *source* of
  the same tag, which the `on_macos`/`on_linux` blocks override wherever a
  binary exists, plus `depends_on arch:` stating the restriction. That is
  core's own shape -- see `graalvm`, whose top-level url is a source archive
  and whose `on_macos` block holds nothing but `depends_on arch: :arm64`. Here
  the source is never fetched: the requirement fails first. Only
  `deckhouse-cli` needs this; `deckhouse-module-tool`, `flant-flint`,
  `onion-gen`, `werf@2` and `werf@3` publish all four binaries.
- A **cask** builds one url from `arch`/`os` helpers and lists a `sha256` only
  for the platforms that exist, exactly as homebrew-cask's `recordly` does with
  its single Linux build. The combinations upstream does not publish render a
  url that 404s and carry no checksum; `depends_on arch:` in the matching
  `on_macos`/`on_linux` block is what refuses to install them. `Cask/NoOverrides`
  forbids a top-level `url`/`sha256` that an `on_*` block overrides, and
  `Cask/OnSystemConditionals` forbids a `sha256` directly inside `on_macos` or
  `on_linux`, so this layout is also the only cop-clean one.

Never silence the check by repeating another architecture's artifact under
`on_arm`/`on_intel`: the package would then advertise a build that does not
exist, which is what the url pattern above avoids.

`brew style` catches none of this and neither does `brew audit`. `task readall`
(part of `task audit`) runs the same check `brew tap` does. After touching a
package's url or `sha256` layout, also run
`task update -- <name> --set <any newer version> --dry-run`: the shapes that
satisfy `Readall` are not all shapes the bump script can rewrite.

The failure is invisible locally while the tap is symlinked, because `brew tap`
never runs on it -- and invisible on a machine that has not trusted the tap,
because untrusted files are skipped before verification. It surfaces on a fresh
machine whose `trust.json` arrived with the dotfiles.

**Never edit a `bottle do` block** — BrewTestBot owns those checksums.

**A bare name resolves to `homebrew/core` first.** Check
`brew info --json=v2 --formula <name>` before naming anything: it reports the tap
a name actually resolves to. `flant-flint` is named that way because core's
`flint` is an unrelated library — and note core's `werf` (2.x, from source)
shadows the bare name, so only `mihalych-pro/tap/werf` reaches the alias below.

**werf is two versioned formulae plus an alias, as core does for `openssl`.**
`Formula/w/werf@2.rb` (`WerfAT2`) and `Formula/w/werf@3.rb` (`WerfAT3`) are
the real formulae; each livecheck sees only its own series. `Aliases/werf` is a
symlink to whichever is the default, and that one is linked while the other
carries `keg_only :versioned_formula`, since both install `bin/werf`. There is
no `Formula/w/werf.rb`, and none must be added: the alias wins name resolution,
so such a file would be silently unreachable -- `brew audit` does not notice.

To make 3.x the default -- once upstream publishes `channels/3/stable`:

1. `ln -sfn ../Formula/w/werf@3.rb Aliases/werf`
2. Move `keg_only :versioned_formula` from `werf@3.rb` to `werf@2.rb`.
3. Point `werf@3`'s livecheck at `channels/3/stable` (`:page_match`, like
   `werf@2`) instead of GitHub releases.
4. `task docs`, `task audit`.

Installs made through `mihalych-pro/tap/werf` record the alias, so
`brew upgrade` follows it to the new target and unlinks the old keg
(`Formula#latest_formula`, `follow_installed_alias`). Installs made by an
explicit `werf@2` stay where they are.

Do not add `werf` to `formula_renames.json`: `brew audit --tap` rejects a name
that is both an alias and a rename, and it is not needed -- `possible_names`
includes aliases, so an old `Cellar/werf` keg from this tap already counts as an
installed `werf@2`. The same rule means a machine with core's `werf` installed
must uninstall it before installing the tap's alias target.

## Test blocks

A `test do` block must actually exercise the binary: at least one assertion
beyond `--version` or `--help`. Existing formulae show the pattern — `d8 k
version --client`, `dmt lint` on a throwaway module, `werf config graph`.

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

Both run on `ubuntu-latest`. A Linux **arm** runner would not work —
`deckhouse-cli` publishes no linux-arm64 asset, so the formula has no url to
load there.

## Reference

- [Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Cask Cookbook](https://docs.brew.sh/Cask-Cookbook)
- [`brew` manpage](https://docs.brew.sh/Manpage) or `man brew`
