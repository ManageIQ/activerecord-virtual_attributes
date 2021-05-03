%w(5.2.4.4 6.0.3.4 6.1.1).each do |ar_version|
  appraise "gemfile-#{ar_version.split('.').first(2).join}" do
    gem "activerecord", "~> #{ar_version}"
      gem "mysql2"
      gem "pg"
      gem "sqlite3"
  end
end
