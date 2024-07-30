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

    # in essence, this is our Arel::Nodes::VirtualAttribute
    class Arel::Nodes::Grouping
      attr_accessor :name, :relation

      # methods from Arel::Nodes::Attribute
      def type_caster
        relation.type_for_attribute(name)
      end

      # Create a node for lowering this attribute
      def lower
        relation.lower(self)
      end

      def type_cast_for_database(value)
        relation.type_cast_for_database(name, value)
      end

      # rubocop:disable Rails/Delegate
      def able_to_type_cast?
        relation.able_to_type_cast?
      end
      # rubocop:enable Rails/Delegate
    end

    module VirtualArel
      # This arel table proxy. This allows WHERE clauses to use virtual attributes
      class ArelTableProxy < Arel::Table
        # overrides Arel::Table#[]
        # adds aliases and virtual attribute arel (aka sql)
        #
        # @returns Arel::Attributes::Attribute|Arel::Nodes::Grouping|Nil
        # for regular database columns:
        #     returns an Arel::Attribute (just like Arel::Table#[])
        # for virtual attributes:
        #     returns the arel for the value
        # for non sql friendly virtual attributes:
        #     returns nil
        def [](name, table = self)
          if (col_alias = @klass.attribute_alias(name))
            name = col_alias
          end
          if @klass.virtual_attribute?(name)
            @klass.arel_for_virtual_attribute(name, table)
          else
            super
          end
        end
      end

      extend ActiveSupport::Concern

      included do
        class_attribute :_virtual_arel, :instance_accessor => false
        self._virtual_arel = {}
      end

      module ClassMethods
        # ActiveRecord::Core 6.1
        def arel_table
          @arel_table ||= ArelTableProxy.new(table_name, :klass => self)
        end

        # supported by sql if any are true:
        # - it is an attribute alias
        # - it is an attribute that is non virtual
        # - it is an attribute that is virtual and has arel defined
        def attribute_supported_by_sql?(name)
          load_schema
          try(:attribute_alias?, name) ||
            (has_attribute?(name) && (!virtual_attribute?(name) || !!_virtual_arel[name.to_s]))
        end

        # private api
        #
        # @return [Nil|Arel::Nodes::Grouping]
        #   for virtual attributes:
        #       returns the arel for the column
        #   for non sql friendly virtual attributes:
        #       returns nil
        def arel_for_virtual_attribute(column_name, table) # :nodoc:
          arel_lambda = _virtual_arel[column_name.to_s]
          return unless arel_lambda

          arel = arel_lambda.call(table)
          arel = Arel::Nodes::Grouping.new(arel) unless arel.kind_of?(Arel::Nodes::Grouping)
          arel.name = column_name
          arel.relation = table
          arel
        end

        private

        def define_virtual_arel(name, arel) # :nodoc:
          self._virtual_arel = _virtual_arel.merge(name => arel)
        end
      end
    end
  end
end

# fixed in https://github.com/rails/rails/pull/45642
if ActiveRecord.version < Gem::Version.new(7.1)
module Arel # :nodoc: all
  # rubocop:disable Naming/MethodName
  # rubocop:disable Naming/MethodParameterName
  # rubocop:disable Style/ConditionalAssignment
  module Visitors
    # rails 6.1...
    class ToSql
      private

      def visit_Arel_Nodes_HomogeneousIn(o, collector)
        collector.preparable = false

        # change:
        # See https://github.com/rails/rails/pull/45642
        visit(o.left, collector)
        # /change

        if o.type == :in
          collector << " IN ("
        else
          collector << " NOT IN ("
        end

        values = o.casted_values

        if values.empty?
          collector << @connection.quote(nil)
        else
          collector.add_binds(values, o.proc_for_binds, &bind_block)
        end

        collector << ")"
      end
    end
  end
  # rubocop:enable Naming/MethodName
  # rubocop:enable Naming/MethodParameterName
  # rubocop:enable Style/ConditionalAssignment
end
end
