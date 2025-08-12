# frozen_string_literal: true

require_relative "lib/xrpl_sale/version"

Gem::Specification.new do |spec|
  spec.name = "xrplsale"
  spec.version = XRPLSale::VERSION
  spec.authors = ["XRPL.Sale Team"]
  spec.email = ["developers@xrpl.sale"]

  spec.summary = "Official Ruby SDK for XRPL.Sale platform integration"
  spec.description = "Ruby SDK for integrating with the XRPL.Sale platform - the native XRPL launchpad for token sales and project funding. Includes Rails integration and comprehensive API support."
  spec.homepage = "https://xrpl.sale"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/xrplsale/ruby-sdk"
  spec.metadata["changelog_uri"] = "https://github.com/xrplsale/ruby-sdk/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://docs.xrpl.sale"
  spec.metadata["bug_tracker_uri"] = "https://github.com/xrplsale/ruby-sdk/issues"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"
  spec.add_dependency "faraday-net_http", "~> 3.0"
  spec.add_dependency "zeitwerk", "~> 2.6"

  # Optional Rails integration
  spec.add_dependency "activesupport", ">= 6.0"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "vcr", "~> 6.1"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rubocop-rspec", "~> 2.0"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "simplecov", "~> 0.21"

  # Rails integration (optional)
  spec.add_development_dependency "rails", ">= 6.0"
  spec.add_development_dependency "sqlite3", "~> 1.4"

  # For building the gem
  spec.add_development_dependency "bundler", "~> 2.0"
end