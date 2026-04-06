#
# Sometimes it is not necessary to know the exact number of queries it takes to preload a record
# Instead, it is necessary only to know that the values actually do get preloaded
#
# This takes a relation or array as a block or argument.
# It runs order by id if it is not already ordered
# It loads the relation if necessary (by running load)
#
# It then ensures the correct values, and in the process, counts queries to ensure they were preloaded
#
# If a single value is passed in, it assumes all records have the same value
#
# Example usage:
#   expect(MyModel.includes(:relation)).to preload_values(:attribute, "foo")
#   expect { MyModel.includes(:relation).to_a }.to preload_values(:attribute, %w[foo bar baz])
#
# Which is similar to:
#   expect(MyModel.includes(:relation).map(&:attribute)).to eq(%w[foo foo foo])

RSpec::Matchers.define :preload_values do |field, expected_values|
  match(:notify_expectation_failures => true) do |block|
    records = block.respond_to?(:call) ? block.call : block
    records = order_by_id(records)
    records.try(:load)

    counter = DBQueryMatchers::QueryCounter.new
    @field = field
    @count = ActiveSupport::Notifications.subscribed(counter.to_proc, 'sql.active_record') do
      if records.respond_to?(:map)
        expected_values = Array.new(records.size, expected_values) unless expected_values.kind_of?(Array)
        actual = records.map { |record| record.send(field) }
      else
        actual = records.send(field)
      end

      # assuming an array and not a hash
      if records.respond_to?(:map)
        actual = actual.map { |v| v.respond_to?(:each) && !v.try(:loaded?) ? order_by_id(v) : v }
        expected_values = expected_values.map { |v| v.respond_to?(:each) && !v.try(:loaded?) ? order_by_id(v) : v }
      end

      # we are mapping actual and expected
      # hold onto them for a little bit in cause they do not match (i.e.: @match == false)
      @expected_values = expected_values
      @actual_values   = actual
      @match = values_match?(actual, expected_values)

      counter.count
    end
    @match && @count == 0
  end

  failure_message do |_actual|
    if !@match
      "Did not fully preload #{@field}. expected: #{@expected_values} got: #{@actual_values}"
    else
      "Expected to preload #{@field} but executed #{@count} queries instead"
    end
  end

  failure_message_when_negated do |_actual|
    "Unexpectedly preloaded #{@field}"
  end

  supports_block_expectations

  def order_by_id(value)
    if value.respond_to?(:order)
      value.try(:order_values).blank? ? value.order(:id) : value
    elsif value.respond_to?(:sort_by)
      value.sort_by(&:id)
    else
      value
    end
  end
end
