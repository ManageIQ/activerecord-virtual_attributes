lib = File.expand_path("lib", __dir__)
$LOAD_PATH.push(lib) unless $LOAD_PATH.include?(lib)

require "active_record/virtual_attributes/version"

Gem::Specification.new do |spec|
  spec.name          = "activerecord-virtual_attributes"
  spec.version       = ActiveRecord::VirtualAttributes::VERSION
  spec.authors       = ["Keenan Brock"]
  spec.email         = ["keenan@thebrocks.net"]

  spec.summary       = "Access non-sql attributes from sql"
  spec.description   = "Define attributes in arel"
  spec.homepage      = "https://github.com/ManageIQ/activerecord-virtual_attributes"
  spec.license       = "Apache 2.0"
  spec.metadata      = {
    "homepage_uri"          => spec.homepage,
    "source_code_uri"       => "https://github.com/ManageIQ/activerecord-virtual_attributes",
    "changelog_uri"         => "https://github.com/ManageIQ/activerecord-virtual_attributes/blob/master/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|bin)/}) || f.match(/^(\.)|renovate.json/) }
  end

  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord", "~> 8.0.4"

  spec.add_development_dependency "byebug"
  spec.add_development_dependency "database_cleaner-active_record", "~> 2.1"
  spec.add_development_dependency "db-query-matchers"
  spec.add_development_dependency "manageiq-style", ">= 1.5.4"

  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", ">= 0.21.2"
  spec.add_development_dependency "sqlite3"
end
