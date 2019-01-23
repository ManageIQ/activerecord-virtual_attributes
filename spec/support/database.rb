require "logger"
require "active_record"

class Database
  attr_accessor :dirname, :adapter
  def initialize
    @dirname = "#{File.dirname(__FILE__)}/../db"
  end

  def adapter
    ENV['DB'] ||= "sqlite3"
  end

  def setup
    I18n.enforce_available_locales = false if defined?(I18n) && I18n.respond_to?(:enforce_available_locales=)

    log = Logger.new(STDERR)
    # log = Logger.new('db.log')
    # log.sev_threshold = Logger::DEBUG
    log.level = Logger::Severity::UNKNOWN
    ActiveRecord::Base.logger = log
    self
  end

  def migrate
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Base.configurations = YAML::load(ERB.new(IO.read("#{dirname}/database.yml")).result)
    ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations[adapter]

    require "#{dirname}/schema"
    require "#{dirname}/models"

    self
  end
end

Database.new.setup.migrate
