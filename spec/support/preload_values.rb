#
# Sometimes, it is not necessary to know the exact number of queries it takes to preload a record
# Instead it is only necessary to know that the values actually do get preloaded
#
# This takes a relation or array as a block or argument.
# It runs order by id if it is not already ordered
# It loads the relation if necessary (by running load)
#
# It then ensures the correct values, and in the process counts queries to ensure they were preloaded
#
# If a single value is passed it, it assumes all records have the same value
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
    records = records.try(:order, :id) if records.respond_to?(:order) && records.try(:order_values).blank?
    records.try(:load)

    @field = field
    @count = ActiveRecord::QueryCounter.count do
      if records.respond_to?(:map)
        expected_values = Array.new(records.size, expected_values) unless expected_values.kind_of?(Array)
        actual = records.map { |record| record.send(field) }
      else
        actual = records.send(field)
      end
      expect(actual).to eq(expected_values)
    end
    @count == 0
  end

  failure_message do |_actual|
    "Expected to preload #{@field} but executed #{@count} queries instead"
  end

  failure_message_when_negated do |_actual|
    "Unexpectedly preloaded #{@field}"
  end

  supports_block_expectations
end
