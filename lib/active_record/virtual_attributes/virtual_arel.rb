module ActiveRecord
  module VirtualAttributes
    # VirtualArel associates arel with an attribute
    #
    # Model.virtual_attribute :field, :string, :arel => ->(t) { t.grouping(t[:field2]) } }
    # Model.select(:field)
    #
    # is equivalent to:
    #
    # Model.select(Model.arel_table.grouping(Model.arel_table[:field2]).as(:field))
    # Model.attribute_supported_by_sql?(:field) # => true
    class Arel::Nodes::Grouping
      attr_accessor :name
    end

    module VirtualArel
      extend ActiveSupport::Concern

      included do
        class_attribute :_virtual_arel, :instance_accessor => false
        self._virtual_arel = {}
      end

      module ClassMethods
        def arel_attribute(column_name, arel_table = self.arel_table)
          load_schema
          if virtual_attribute?(column_name) && !attribute_alias?(column_name)
            if (col = _virtual_arel[column_name.to_s])
              arel = col.call(arel_table)
              arel.name = column_name if arel.kind_of?(Arel::Nodes::Grouping)
              arel
            end
          else
            arel_table[column_name]
          end
        end

        # supported by sql if
        # - it is an attribute alias
        # - it is an attribute that is non virtual
        # - it is an attribute that is virtual and has arel defined
        def attribute_supported_by_sql?(name)
          load_schema
          try(:attribute_alias?, name) ||
            (has_attribute?(name) && (!virtual_attribute?(name) || !!_virtual_arel[name.to_s]))
        end

        private

        def define_virtual_arel(name, arel)
          self._virtual_arel = _virtual_arel.merge(name => arel)
        end
      end
    end
  end
end
