lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.push(lib) unless $LOAD_PATH.include?(lib)
require "virtual_attributes/version"

Gem::Specification.new do |spec|
  spec.name          = "virtual_attributes"
  spec.version       = VirtualAttributes::VERSION
  spec.authors       = ["Keenan Brock"]
  spec.email         = ["keenan@thebrocks.net"]

  spec.summary       = %q{Access non-sql attributes from sql}
  spec.description   = %q{Define attributes in arel}
  spec.homepage      = "https://github.com/kbrock/virtual_attributes"
  spec.license       = "Apache 2.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kbrock/virtual_attributes"
  spec.metadata["changelog_uri"] = "https://github.com/kbrock/virtual_attributes/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord", ">= 5.0"

  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
