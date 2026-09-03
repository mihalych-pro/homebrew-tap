# How to Use Homebrew Formulae

Formulae are Homebrew's command-line packages: binaries and libraries installed
into the Homebrew prefix. Casks, covered in [CASK_USAGE.md](CASK_USAGE.md), are
MacOS/Linux applications instead. The packages in this tap are listed in
[FORMULAE.md](FORMULAE.md) and [CASKS.md](CASKS.md).

## Frequently Used Commands

Formulae are the default subject of every `brew` command, so `--formula` is only
needed to disambiguate when a cask shares the name:

- `install` — installs the given formula.
- `uninstall` — uninstalls the given formula.
- `reinstall` — reinstalls the given formula.
- `list --formula` — lists installed formulae.
- `upgrade` — upgrades outdated formulae.

## Adding This Tap

A formula from a third-party tap can be installed either by tapping first or by
its fully-qualified name:

```console
$ brew tap mihalych-pro/tap
$ brew install deckhouse-cli
```

```console
$ brew install mihalych-pro/tap/deckhouse-cli
```

**Prefer the second form.** A bare name resolves to `homebrew/core` first, so it
does not always reach this tap:

- `werf` exists in core as well, at the same version. `brew install werf` gets
  core's build-from-source formula; only `mihalych-pro/tap/werf` gets this one.
- `flant-flint` is deliberately not called `flint` for the same reason, since
  core's `flint` is an unrelated number-theory library.

`brew info --json=v2 --formula <name>` reports which tap a bare name resolves
to, which is worth checking before naming anything new here.

## Searching for Formulae

```console
$ brew search --formula deckhouse
mihalych-pro/tap/deckhouse-cli
mihalych-pro/tap/deckhouse-module-tool
```

Use `brew desc <formula>` to see one-line descriptions, or `brew desc --search
<text>` to search descriptions rather than names.

## Installing Formulae

```console
$ brew install mihalych-pro/tap/werf
```

Homebrew installs into its own directory under `Cellar` and symlinks the
executables onto your `PATH`. A formula that ships prebuilt binaries — as every
formula in this tap does — is simply unpacked; one that builds from source is
compiled, which `--build-from-source` forces even when a bottle exists.

## Uninstalling Formulae

```console
$ brew uninstall werf
```

This removes the versions in the Cellar and the symlinks. Configuration and data
the program wrote into your home directory are left alone.

## Inspecting Installed Formulae

Details about a formula, installed or not:

```console
$ brew info mihalych-pro/tap/werf
==> mihalych-pro/tap/werf: stable 2.75.3
Consistent delivery tool for Kubernetes
https://werf.io/
From: ssh://git@github.com/mihalych-pro/homebrew-tap.git/Formula/w/werf.rb
Tap: mihalych-pro/tap
License: Apache-2.0
==> Installed Versions
werf 2.75.3 (7 files, 103.8MB) [Linked]
```

Which files a formula installed:

```console
$ brew list --formula werf
/opt/homebrew/Cellar/werf/2.75.3/bin/werf
/opt/homebrew/Cellar/werf/2.75.3/etc/bash_completion.d/werf
/opt/homebrew/Cellar/werf/2.75.3/share/zsh/site-functions/_werf
/opt/homebrew/Cellar/werf/2.75.3/share/fish/vendor_completions.d/werf.fish
```

Installed formulae with their versions:

```console
$ brew list --formula --versions
deckhouse-cli 0.33.14
deckhouse-module-tool 0.2.2
flant-flint 2.1.3
werf 2.75.3
```

`brew list --formula --full-name` (without `--versions`) qualifies the names
with their tap, which is how to tell a tap formula from a core one of the same
name.

## Updating and Upgrading

```console
$ brew update            # refresh the tap and Homebrew itself
$ brew outdated          # list what has a newer version
$ brew upgrade           # upgrade everything outdated
$ brew upgrade werf      # or just one formula
```

`brew outdated` prints nothing and exits successfully when everything is
current. To hold a formula at its installed version, use `brew pin <formula>`
(and `brew unpin` to release it).

Old versions stay in the Cellar until `brew cleanup` removes them; `brew cleanup
--dry-run` shows what would go.

## Dependencies

```console
$ brew deps --tree mihalych-pro/tap/werf
mihalych-pro/tap/werf
```

`brew deps` lists what a formula needs, `brew uses --installed <formula>` the
reverse — what would break if you removed it. Formulae in this tap ship
prebuilt, self-contained binaries, so they have no runtime dependencies.

## Other Commands

- `fetch` — downloads a formula's files into the cache without installing.
- `--cache <formula>` — prints where that download lands.
- `unlink` / `link` — removes or restores the symlinks without uninstalling,
  which is how two versions of the same tool can coexist.
- `home` — opens the formula's homepage.
- `doctor` — checks the installation for common problems.
- `style` / `audit` — lint a formula; see [AGENTS.md](AGENTS.md) for the
  maintenance workflow in this tap.

## Shell Completion

Homebrew ships completions for `bash`, `zsh` and `fish`, and formulae in this tap
install their own tool completions alongside the binary (visible in the
`brew list` output above). See
[`brew` Shell Completion](https://docs.brew.sh/Shell-Completion) for enabling
them.

## Other Ways to Specify a Formula

Besides a plain name (`werf`) and a fully-qualified one
(`mihalych-pro/tap/werf`), `brew` also accepts:

- a path to a formula file, _e.g._ `Formula/w/werf.rb`;
- a URL to a formula file;
- a formula file in the working directory — prefix it with `./` to be sure it
  wins over a tapped formula of the same name.
