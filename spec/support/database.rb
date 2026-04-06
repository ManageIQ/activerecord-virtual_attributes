require "logger"
require "active_record"
require "erb"

class Database
  VALID_ADAPTERS = %w[sqlite3 postgresql trilogy].freeze

  def self.adapter
    case ENV.fetch('DB', "sqlite")
    when "sqlite", "sqlite3"          then ENV["DB"] = "sqlite3"
    when "pg", "postgresql"           then ENV["DB"] = "postgresql"
    when "mysql", "mysql2", "trilogy" then ENV["DB"] = "trilogy"
    else
      raise "ENV['DB'] value invalid, must be one of: #{VALID_ADAPTERS.join(", ")}"
    end
  end

  def self.mysql?
    adapter == "trilogy" || adapter == "mysql2"
  end

  attr_accessor :dirname

  def initialize
    @dirname = "#{File.dirname(__FILE__)}/../db"
  end

  def connection_options
    @connection_options ||=
      begin
        if defined?(I18n)
          I18n.enforce_available_locales = false if I18n.respond_to?(:enforce_available_locales=)
          # I18n.fallbacks = [I18n.default_locale] if I18n.respond_to?(:fallbacks=)
        end
        YAML.safe_load(ERB.new(File.read("#{dirname}/database.yml")).result)[self.class.adapter]
      end
  end

  def create
    ActiveRecord::Base.establish_connection(connection_options.except("database"))
    ActiveRecord::Base.connection.create_database(connection_options["database"])
    self
  end

  def drop
    ActiveRecord::Base.establish_connection(connection_options.except("database"))
    ActiveRecord::Base.connection.drop_database(connection_options["database"])
    self
  end

  def connect
    ActiveRecord::Base.establish_connection(connection_options)
    ActiveRecord::Base.connection # Check the connection works
    self
  end

  def migrate
    ActiveRecord::Migration.verbose = false
    connect
    require "#{dirname}/schema"
    require "#{dirname}/models"

    self
  end
end
