require "logger"
require "active_record"
require "erb"

class Database
  VALID_ADAPTERS = %w[sqlite3 postgresql mysql2].freeze

  def self.adapter
    # Handle missing and short-form DB values
    case ENV['DB']
    when nil, "sqlite" then ENV['DB'] = "sqlite3"
    when "pg"          then ENV['DB'] = "postgresql"
    when "mysql"       then ENV['DB'] = "mysql2"
    end
    raise "ENV['DB'] value invalid, must be one of: #{VALID_ADAPTERS.join(", ")}" unless VALID_ADAPTERS.include?(ENV['DB'])

    ENV['DB']
  end

  attr_accessor :dirname

  def initialize
    @dirname = "#{File.dirname(__FILE__)}/../db"
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

    @connection_options = YAML.safe_load(ERB.new(IO.read("#{dirname}/database.yml")).result)[self.class.adapter]

    self
  end

  def migrate
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Base.establish_connection(@connection_options)
    ActiveRecord::Base.connection # Check the connection works

    require "#{dirname}/schema"
    require "#{dirname}/models"

    self
  end
end
