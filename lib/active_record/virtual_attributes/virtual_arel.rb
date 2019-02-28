module ActiveRecord
  module VirtualAttributes
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
            col = _virtual_arel[column_name.to_s]
            col.call(arel_table) if col
          else
            super
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
