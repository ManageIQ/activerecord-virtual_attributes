require "logger"
require "active_record"

class Database
  attr_accessor :dirname

  def initialize
    @dirname = "#{File.dirname(__FILE__)}/../db"
  end

  def adapter
    ENV['DB'] ||= "sqlite3"
  end

  def setup
    if defined?(I18n)
      I18n.enforce_available_locales = false if I18n.respond_to?(:enforce_available_locales=)
      # I18n.fallbacks = [I18n.default_locale] if I18n.respond_to?(:fallbacks=)
    end
    log = Logger.new(STDERR)
    # log = Logger.new('db.log')
    # log.sev_threshold = Logger::DEBUG
    log.level = Logger::Severity::UNKNOWN
    ActiveRecord::Base.logger = log
    self
  end

  def migrate
    ActiveRecord::Migration.verbose = false
    databaseyml = YAML.safe_load(ERB.new(IO.read("#{dirname}/database.yml")).result)
    if ActiveRecord::VERSION::STRING < "6.1"
      ActiveRecord::Base.configurations = databaseyml
      ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations[adapter]
    else
      ActiveRecord::Base.establish_connection databaseyml[adapter]
    end

    require "#{dirname}/schema"
    require "#{dirname}/models"

    self
  end
end

Database.new.setup.migrate
