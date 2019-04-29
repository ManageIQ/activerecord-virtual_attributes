%w(5.0.7 5.1.7 5.2.3 6.0.0).each do |ar_version|
  db_gem = "virtual_attributes"
  appraise "#{db_gem}-#{ar_version.split('.').first(2).join}" do
    gem "activerecord", "~> #{ar_version}"

    if ar_version >= "5.0"
      gem "mysql2"
    elsif ar_version >= "4.2"
      gem "mysql2", "~> 0.4.0"
    end

    if ar_version >= "5.0"
      gem "pg"
    else
      gem "pg", "0.18.4"
    end

    if ar_version >= "5.2"
      gem "sqlite3"
    else
      gem "sqlite3", "~> 1.3.13"
    end
  end
end
