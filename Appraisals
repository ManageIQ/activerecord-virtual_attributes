%w(5.2.3 6.0.0).each do |ar_version|
  appraise "gemfile-#{ar_version.split('.').first(2).join}" do
    gem "activerecord", "~> #{ar_version}"
      gem "mysql2"
      gem "pg"
      gem "sqlite3"
  end
end
