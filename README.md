# mihalych-pro/tap

[![Homebrew tap](https://img.shields.io/badge/Homebrew-tap-FBB040?logo=homebrew&logoColor=white)](https://brew.sh)
[![Bump formulas](https://github.com/mihalych-pro/homebrew-tap/actions/workflows/bump-formulas.yml/badge.svg)](https://github.com/mihalych-pro/homebrew-tap/actions/workflows/bump-formulas.yml)
[![Merge automated bumps](https://github.com/mihalych-pro/homebrew-tap/actions/workflows/merge-automated-prs.yml/badge.svg)](https://github.com/mihalych-pro/homebrew-tap/actions/workflows/merge-automated-prs.yml)
[![License](https://img.shields.io/github/license/mihalych-pro/homebrew-tap)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/mihalych-pro/homebrew-tap)](https://github.com/mihalych-pro/homebrew-tap/commits/main)

A personal [Homebrew](https://brew.sh) taps collection, that refreshes
automatically every six hours.

## What's here

- **[FORMULAE.md](FORMULAE.md)** — command-line tools
- **[CASKS.md](CASKS.md)** — applications

Both lists are generated from the packages themselves, with the current version
and the day it landed.

## Install

The shortest path needs no setup — a fully-qualified name works straight away:

```bash
brew install mihalych-pro/tap/deckhouse-cli      # a formula
brew install --cask mihalych-pro/tap/hytale      # a cask
```

This is the recommended form, and it removes any ambiguity: a bare name resolves
to `homebrew/core` first, and `werf` exists there too, so plain
`brew install werf` would get core's formula rather than this one.

### Short names

To type `brew install deckhouse-cli` instead, tap the repository and vouch for it
once — Homebrew asks for that because loading a third-party tap runs its Ruby:

```bash
brew tap mihalych-pro/tap
brew trust --tap mihalych-pro/tap
```

Short names then work as usual:

```bash
brew install deckhouse-cli
brew install --cask hytale
```

Trusting the tap is a single decision covering everything in it. To be narrower,
vouch per package — `brew trust --formula mihalych-pro/tap/werf`,
`brew trust --cask mihalych-pro/tap/hytale` — and `brew untrust` reverses either.

## Everyday commands

```bash
brew upgrade                       # upgrade everything, this tap included
brew upgrade deckhouse-cli         # or just one package
brew outdated                      # what has a newer version
brew uninstall deckhouse-cli
brew uninstall --cask hytale
brew info mihalych-pro/tap/werf    # version, homepage, installed files
```

`d8`, `werf` and `flint` install their own shell completions, so `d8 <tab>` and
friends work once
[completions are enabled](https://docs.brew.sh/Shell-Completion). `dmt` ships
none — it has no `completion` subcommand upstream.

## Notes worth knowing

- **Binary names differ from package names.** `deckhouse-cli` installs `d8`,
  `deckhouse-module-tool` installs `dmt`, `flant-flint` installs `flint`. The
  former short names still resolve, so `brew install mihalych-pro/tap/d8` keeps
  working.

- **`d8` has no linux-arm64 build.** Upstream publishes none, so that formula
  installs on macOS (Intel and Apple silicon) and Linux x86_64 only.

<!-- - **`flant-flint` carries the prefix on purpose** — `homebrew/core` already has an unrelated `flint`, a number-theory library. -->

## More

- [FORMULA_USAGE.md](FORMULA_USAGE.md) — working with formulae in depth
- [CASK_USAGE.md](CASK_USAGE.md) — working with casks in depth
- [AGENTS.md](AGENTS.md) — maintaining this tap
