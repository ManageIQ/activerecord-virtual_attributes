%w(5.0.7 5.1.6 5.2.0).each do |ar_version|
  db_gem = "virtual_attributes"
  appraise "#{db_gem}-#{ar_version.split('.').first(2).join}" do
    gem "activerecord", "~> #{ar_version}"
    platforms :ruby do
      if ar_version >= "5.0"
        gem "pg"
        gem "mysql2"
      else 
        gem "pg", "0.18.4"
        gem "mysql2", '~> 0.4.0'
      end
      gem "sqlite3"
    end
  end
end
