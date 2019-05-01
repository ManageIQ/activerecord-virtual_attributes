# Derived from code found in http://stackoverflow.com/questions/5490411/counting-the-number-of-queries-performed
#
# Example usage:
#   expect { MyModel.do_the_queries }.to match_query_limit_of(5)

RSpec::Matchers.define :match_query_limit_of do |expected|
  match(:notify_expectation_failures => true) do |block|
    query_count(&block) == expected
  end

  failure_message do |_actual|
    "Expected #{expected} queries, got #{@counter.query_count}"
  end

  description do
    "expect the block to execute certain number of queries"
  end

  supports_block_expectations

  def query_count(&block)
    @counter = ActiveRecord::QueryCounter.new
    ActiveSupport::Notifications.subscribed(@counter.to_proc, 'sql.active_record', &block)
    @counter.query_count
  end
end
