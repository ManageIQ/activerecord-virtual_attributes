module ActiveRecord
  module VirtualAttributes
    class Ruby
      def initialize(value)
        @value = value
      end

      def inspect
        @value
      end
    end
  end
end
