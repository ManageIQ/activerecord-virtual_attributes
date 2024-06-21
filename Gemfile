# Main Gemfile (vs Appraisal version)

source "https://rubygems.org"

minimum_version =
  case ENV['TEST_RAILS_VERSION']
  when "7.0"
    "~>7.0.8"
  else
    "~>6.1.4"
  end

gem "activerecord", minimum_version
gem "mysql2"
gem "pg"
gem "sqlite3", "< 2"

gemspec
