if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require "bundler/setup"
require "active_record/virtual_attributes"
require "active_record/virtual_attributes/rspec"

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.expose_dsl_globally = false

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
