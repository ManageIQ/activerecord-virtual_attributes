%w(5.0.7 5.1.6 5.2.0).each do |ar_version|
  db_gem = "virtual_attributes"
  appraise "#{db_gem}-#{ar_version.split('.').first(2).join}" do
    gem "activerecord", "~> #{ar_version}"

    if ar_version >= "5.1"
      gem "pg"
      gem "mysql2"
      gem "sqlite3"
    else
      gem "sqlite3", "~> 1.3.6"
      gem "pg", " ~> 0.18.4"
      gem "mysql2", '~> 0.4.0'
    end
  end
end
