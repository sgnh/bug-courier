# frozen_string_literal: true

require_relative "lib/bug_courier/version"

Gem::Specification.new do |spec|
  spec.name = "bug_courier"
  spec.version = BugCourier::VERSION
  spec.authors = ["Steffen Hansen"]
  spec.email = ["sgnh@users.noreply.github.com"]

  spec.summary = "Automatically create GitHub issues from uncaught Rails exceptions."
  spec.description = "A Rails gem that catches uncaught exceptions and automatically creates GitHub issues with full error details, backtraces, and request context. Includes deduplication to avoid flooding your repo with duplicate issues."
  spec.homepage = "https://github.com/sgnh/bug-courier"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sgnh/bug-courier"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 7.0"
  spec.add_dependency "net-http"
end
