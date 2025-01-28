# Main Gemfile (vs Appraisal version)

source "https://rubygems.org"

minimum_version =
  case ENV['TEST_RAILS_VERSION']
  when "7.2"
    "~>7.2.1"
  when "7.1"
    "~>7.1.4"
  else
    "~>7.0.8"
  end

gem "activerecord", minimum_version

gem "mysql2"
gem "pg"
gem "sqlite3", "< 2"

gemspec
