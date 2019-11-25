# Derived from code found in http://stackoverflow.com/questions/5490411/counting-the-number-of-queries-performed
#
# Example usage:
#   expect { MyModel.do_the_queries }.to match_query_limit_of(5)

RSpec::Matchers.define :match_query_limit_of do |expected|
  match(:notify_expectation_failures => true) do |block|
    @count = ActiveRecord::QueryCounter.count(&block)
    @count == expected
  end

  failure_message do |_actual|
    "Expected #{expected} queries, got #{@count}"
  end

  failure_message_when_negated do
    "Expect not to execute #{expected} queries"
  end

  supports_block_expectations
end
