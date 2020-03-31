# this is from https://github.com/rails/arel/pull/435
# this allows sorting and where clauses to work with virtual_attribute columns
# no longer needed for rails 6.0 and up (change was merged)
if ActiveRecord.version.to_s < "6.0" && defined?(Arel::Nodes::Grouping)
  module Arel
    module Nodes
      class Grouping
        include Arel::Expressions
        include Arel::AliasPredication
        include Arel::OrderPredications
        include Arel::Math
      end
    end
  end
end
