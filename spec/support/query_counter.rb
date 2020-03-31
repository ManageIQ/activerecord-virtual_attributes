# From http://stackoverflow.com/a/13423584/153896
module ActiveRecord
  class QueryCounter
    attr_reader :query_count

    def initialize
      @query_count = 0
    end

    def to_proc
      lambda(&method(:callback))
    end

    def callback(_name, _start, _finish, _message_id, values)
      @query_count += 1 unless %w[CACHE SCHEMA].include?(values[:name])
    end

    def self.count(&block)
      counter = ActiveRecord::QueryCounter.new
      ActiveSupport::Notifications.subscribed(counter.to_proc, 'sql.active_record', &block)
      counter.query_count
    end
  end
end
