# typed: false
# frozen_string_literal: true

# Bump every formula and cask in this tap to its latest upstream release.
#
# Run through Homebrew's own Ruby, so that Homebrew's classes do the work:
#
#   brew ruby scripts/update-formulas.rb -- [names] [--dry-run] [--force] [--set VERSION]
#   brew ruby scripts/update-formulas.rb -- --outdated   # names only, one per line
#
# The `--` is required because `brew ruby` would otherwise claim the flags.
# `task update` passes it for you.
#
# Nothing here shells out. Everything runs inside this one Ruby process:
#
#   Tap#formula_files / #cask_files      which packages exist
#   Formulary / Cask::CaskLoader         the package objects
#   Homebrew::Livecheck                  what the latest version is
#   Resource#fetch + Pathname#sha256     checksums, via brew's own cache
#   Utils::AST                           parsing and rewriting the .rb files
#   Homebrew::DevCmd::BumpCaskPr         casks, as a class rather than a fork
#
# Loading the package objects requires the tap to be trusted once, because that
# evaluates its Ruby:
#
#   brew trust --tap mihalych-pro/tap
#
# Every formula is rewritten here, whether its `url`/`sha256` pair sits in the
# class body or one pair per platform inside `on_macos`/`on_linux`. Homebrew's
# own `bump-formula-pr` handles only the first shape, because
# `Utils::AST::FormulaAST` looks at direct children of the formula class body
# and nothing deeper, so walking the AST ourselves covers both.
#
# Casks are the exception and stay with `bump-cask-pr` -- see the comment on
# `bump_cask_with_homebrew` for why substitution cannot work there.
#
# (Homebrew's own downloader still runs `curl` underneath `Resource#fetch`;
# avoiding that would mean reimplementing downloads and losing its cache,
# mirrors and retries.)

require "cask/cask_loader"
require "dev-cmd/bump-cask-pr"
require "livecheck/livecheck"
require "resource"
require "utils/ast"
require "utils/output"
require "utils/tar"

# Wrapped in a module: defining constants or methods at the top level would
# collide with Homebrew's own (an `Options` struct shadows Homebrew::Options
# and breaks formula loading outright).
module TapUpdater
  # `odie` and friends live in Utils::Output::Mixin, not Kernel, so a module has
  # to pull them in explicitly.
  extend Utils::Output::Mixin

  module_function

  TAP_NAME = "mihalych-pro/tap"

  # Blocks whose `url`/`sha256` are not ours to touch: bottle checksums belong to
  # BrewTestBot, a resource pins its own version, and a livecheck url is a version
  # manifest rather than an artifact. `on_*` blocks are deliberately not here.
  FOREIGN_BLOCKS = [:bottle, :resource, :livecheck, :patch, :test, :service, :head].freeze

  Settings = Struct.new(:names, :dry_run, :force, :set_version, :list_outdated)

  def parse_options(argv)
    options = Settings.new([], false, false, nil, false)
    until argv.empty?
      case (argument = argv.shift)
      when "--dry-run" then options.dry_run = true
      when "--outdated" then options.list_outdated = true
      when "--force" then options.force = true
      when "--set" then options.set_version = argv.shift || odie("--set needs a version")
      when /\A--set=(.+)\z/ then options.set_version = Regexp.last_match(1)
      when "-h", "--help"
        puts File.read(__FILE__)[/(?<=\n)# Bump.*?(?=\n\n)/m]
        exit 0
      when /\A-/ then odie "unknown option: #{argument}"
      else options.names << argument
      end
    end
    odie "--set applies to exactly one package" if options.set_version && options.names.length != 1
    options
  end

  def token_of(package) = package.is_a?(Formula) ? package.name : package.token
  def kind_of(package) = package.is_a?(Formula) ? "formula" : "cask"
  def path_of(package) = package.is_a?(Formula) ? package.path : package.sourcefile_path

  # Building a Formula or Cask object evaluates the tap's own Ruby, which is why
  # Homebrew gates it behind `brew trust`. An untrusted package is reported as a
  # failure rather than quietly skipped, so a newly added one can never fall out
  # of the update unnoticed.
  #
  # Returns [packages, untrusted names].
  def load_packages
    tap = Tap.fetch(TAP_NAME)
    untrusted = []

    packages = Homebrew::API.with_no_api_env do
      loaders = tap.formula_files.to_h { |path| [path, -> { Formulary.factory(path) }] }
                   .merge(tap.cask_files.to_h { |path| [path, -> { Cask::CaskLoader.load(path) }] })
      loaders.filter_map do |path, load|
        load.call
      rescue Homebrew::UntrustedTapError
        untrusted << path.basename(".rb").to_s
        nil
      end
    end

    if untrusted.any?
      onoe "untrusted, cannot be loaded: #{untrusted.sort.join(", ")}"
      puts "  vouch for the tap once with: brew trust --tap #{TAP_NAME}"
    end

    [packages, untrusted.sort]
  end

  # The version the file currently declares. Read off the package itself, never
  # from livecheck: livecheck may skip a package entirely, and a blank current
  # version would make the url rewriting below substitute on an empty string.
  def current_version(package)
    package.is_a?(Formula) ? package.stable&.version : Version.new(package.version)
  end

  # Returns [latest, skip_reason]; latest is nil when unresolvable.
  def check_latest(package)
    skip = Homebrew::Livecheck::SkipConditions.skip_information(package, verbose: false)
    if skip.present?
      reason = Array(skip[:messages]).join("; ").presence || skip[:status]
      return [nil, reason]
    end

    latest = Homebrew::Livecheck.latest_version(package)&.fetch(:latest)
    return [nil, "unable to resolve the latest version"] if latest.blank?

    [latest, nil]
  end

  def outdated?(package, current, latest)
    create = ->(version) { Homebrew::Livecheck::LivecheckVersion.create(package, version) }
    create.call(current) < create.call(latest)
  end

  # Casks are left to Homebrew's own command, instantiated rather than forked.
  #
  # A cask's `url` is built by interpolation -- `hytale-launcher-#{version}.dmg`
  # holds no version literal -- so the new url cannot be derived by substitution
  # the way a formula's can. Resolving it means re-evaluating the cask with the
  # new version, once per os/arch, which is exactly what bump-cask-pr already
  # does (see its `FromContentLoader` pass and os x arch product). Re-deriving
  # that here would duplicate subtle logic guarding checksums, so it stays.
  #
  # Caution: this was observed writing one platform's checksum for a cask with
  # per-OS `on_macos`/`on_linux` blocks, and then leaving the wrong value in
  # place on later runs. Prefer keeping cask urls interpolated with nothing but
  # `version`, which routes them through the rewriter above instead.
  #
  # It reports failure by calling `odie`, which raises a catchable SystemExit;
  # turn that into a normal error so one bad package does not end the run.
  def bump_cask_with_homebrew(package, version, dry_run:)
    argv = ["--write-only", "--no-audit", "--version=#{version}", "#{TAP_NAME}/#{token_of(package)}"]

    if dry_run
      puts "  would run: bump-cask-pr #{argv.join(" ")}"
      return
    end

    Homebrew.failed = false
    begin
      Homebrew::DevCmd::BumpCaskPr.new(argv).run
    rescue SystemExit => e
      raise "bump-cask-pr exited with status #{e.status}"
    end
    raise "bump-cask-pr reported a failure" if Homebrew.failed?
  end

  def artifact_urls(root)
    root.each_node(:send).select do |node|
      node.method_name == :url && node.receiver.nil? &&
        node.first_argument&.type?(:str, :dstr) &&
        node.each_ancestor(:block).none? { |block| FOREIGN_BLOCKS.include?(block.method_name) } &&
        node.each_ancestor(:def).none?
    end
  end

  # True when a `"...#{version}..."` url interpolates nothing but `version`, so
  # its concrete url can be rendered for any version without evaluating the
  # package. `#{arch}` or `version.csv.first` are not handled.
  def version_only_interpolation?(argument)
    argument.children.all? do |child|
      next true if child.str_type?
      next false if !child.type?(:begin) || !child.children.one?

      call = child.children.first
      call.send_type? && call.receiver.nil? && call.method_name == :version && call.arguments.empty?
    end
  end

  # The concrete url this stanza points at for `version`, or nil if it cannot be
  # worked out without evaluating the package.
  def rendered_url(argument, version)
    if argument.str_type?
      argument.str_content
    elsif version_only_interpolation?(argument)
      argument.children.map { |child| child.str_type? ? child.str_content : version.to_s }.join
    end
  end

  # The `sha256` sitting beside a `url`: in the same `on_*` block for a
  # per-platform pair, or in the formula class body for a plain source formula.
  def paired_sha256(url_node)
    enclosing = url_node.each_ancestor(:block).first || url_node.each_ancestor(:class).first
    siblings = Utils::AST.body_children(enclosing&.body)
    siblings.grep(Utils::AST::SendNode).find do |node|
      node.method_name == :sha256 && node.first_argument&.str_type?
    end
  end

  # A top-level `version`: what GoReleaser emits alongside per-platform urls in
  # a formula, and what every cask carries. A cask's whole body sits inside the
  # `cask "token" do` block, so that one ancestor has to be tolerated.
  def version_stanza(root, current)
    root.each_node(:send).find do |node|
      node.method_name == :version && node.receiver.nil? &&
        node.each_ancestor(:block).none? { |block| block.method_name != :cask } &&
        node.each_ancestor(:def).none? &&
        Utils::AST.literal_value(node.first_argument) == current.to_s
    end
  end

  # Every artifact url must be resolvable for an arbitrary version: either it
  # spells the current one out, or it interpolates nothing but `version`.
  def rewritable?(package, current)
    return false if current.blank?

    _processed_source, root = Utils::AST.process_source(path_of(package).read)
    url_nodes = artifact_urls(root)
    url_nodes.any? && url_nodes.all? do |node|
      url = rendered_url(node.first_argument, current)
      url.present? && url.include?(current.to_s)
    end
  end

  def checksum_for(name, url, version)
    resource = Resource.new
    resource.url(url)
    resource.owner = Resource.new(name)
    resource.version(version.to_s)

    # The checksum is what we are here to compute, so there is nothing to
    # verify against: without these flags every artifact prints a progress bar
    # and a "Cannot verify integrity" warning, which buries the real output.
    file = resource.fetch(verify_download_integrity: false, quiet: true)
    Utils::Tar.validate_file(file)
    file.sha256
  end

  def bump_by_rewriting(package, current, version, dry_run:)
    # A blank `current` would make the gsub below match the empty string and
    # splice the version between every character of the url.
    raise "current version unknown, refusing to rewrite urls" if current.blank?

    path = path_of(package)
    processed_source, root = Utils::AST.process_source(path.read)
    rewriter = Utils::AST::TreeRewriter.new(processed_source.buffer)

    url_nodes = artifact_urls(root)
    raise "found no artifact urls to rewrite" if url_nodes.empty?

    url_nodes.each do |url_node|
      sha_node = paired_sha256(url_node) ||
                 raise("url on line #{url_node.first_line} has no sha256 beside it")

      argument = url_node.first_argument
      old_url = rendered_url(argument, current) ||
                raise("url on line #{url_node.first_line} interpolates more than `version`")
      raise "version #{current} not present in #{old_url}" unless old_url.include?(current.to_s)

      # A literal url has to have the version swapped in its own text; an
      # interpolated one renders the new version by itself once the `version`
      # stanza is updated. Either way the checksum is recomputed from the url
      # this stanza will actually resolve to.
      new_url = if argument.str_type?
        old_url.gsub(current.to_s, version.to_s)
      else
        rendered_url(argument, version)
      end
      if dry_run
        puts "  #{new_url}\n    (not fetched)"
        next
      end

      checksum = checksum_for(token_of(package), new_url, version)
      puts "  #{new_url}\n    #{checksum}"
      if argument.str_type?
        rewriter.replace(argument.source_range, Utils::AST.ruby_literal(new_url))
      end
      rewriter.replace(sha_node.first_argument.source_range, Utils::AST.ruby_literal(checksum))
    end

    if (node = version_stanza(root, current))
      puts "  version stanza -> #{version}"
      rewriter.replace(node.first_argument.source_range, Utils::AST.ruby_literal(version.to_s)) unless dry_run
    end

    contents = rewriter.process

    # A new version invalidates any revision, which would otherwise keep
    # inflating the version as `1.2.3_2`. `bump-formula-pr` drops it the same
    # way; a second FormulaAST pass is needed because its rewriter is its own.
    # Casks have no revision stanza at all.
    if package.is_a?(Formula) && package.revision.nonzero?
      puts "  dropped revision #{package.revision}"
      unless dry_run
        formula_ast = Utils::AST::FormulaAST.new(contents)
        formula_ast.remove_stanza(:revision)
        contents = formula_ast.process
      end
    end

    path.atomic_write(contents) unless dry_run
  end

  def main(argv)
    options = parse_options(argv)

    packages, untrusted = load_packages
    if options.names.any?
      packages.select! { |package| options.names.include?(token_of(package)) }
      untrusted &= options.names
    end
    if (unknown = options.names - packages.map { |p| token_of(p) } - untrusted).any?
      odie "not in #{TAP_NAME}: #{unknown.join(", ")}"
    end
    # Nothing loadable would otherwise read as "everything up to date", which on
    # a fresh checkout is exactly the wrong conclusion.
    odie "no packages could be loaded from #{TAP_NAME}" if packages.empty?

    # Third-party taps may ship their own livecheck strategies.
    Homebrew::Livecheck.load_other_tap_strategies(packages)

    # `--outdated` exists for CI, which opens one pull request per package and
    # so needs the list before touching any file.
    if options.list_outdated
      packages.sort_by { |package| token_of(package) }.each do |package|
        latest, skip_reason = check_latest(package)
        next if skip_reason
        next unless outdated?(package, current_version(package), latest)

        puts token_of(package)
      end
      return
    end

    changed = []
    # An untrusted package is a failure, not a silent omission.
    failed = untrusted.dup

    packages.sort_by { |package| token_of(package) }.each do |package|
      label = "#{token_of(package)} (#{kind_of(package)})"
      current = current_version(package)
      latest, skip_reason = check_latest(package)

      if options.set_version
        target = options.set_version
      elsif skip_reason
        puts "#{label}: skipped - #{skip_reason}"
        next
      elsif !options.force && !outdated?(package, current, latest)
        puts "#{label}: #{current} (up to date)"
        next
      else
        target = latest
      end

      puts "#{label}: #{current} -> #{target}"
      begin
        if rewritable?(package, current)
          bump_by_rewriting(package, current, target, dry_run: options.dry_run)
        elsif package.is_a?(Cask::Cask)
          bump_cask_with_homebrew(package, target, dry_run: options.dry_run)
        else
          raise "no url holds #{current} literally; bump it with `brew bump-formula-pr`"
        end
        changed << token_of(package)
      rescue => e
        onoe "#{token_of(package)}: #{e.message}"
        failed << token_of(package)
      end
    end

    puts "\nUpdated: #{changed.join(", ")}. Verify with: task audit" if changed.any? && !options.dry_run
    odie "Failed: #{failed.join(", ")}" if failed.any?
  end
end

TapUpdater.main(ARGV)
