module VirtualAttributes
  module VirtualTotal
    extend ActiveSupport::Concern

    module ClassMethods
      private

      # define an attribute to calculate the total of a has many relationship
      #
      #  example:
      #
      #    class ExtManagementSystem
      #      has_many :vms
      #      virtual_total :total_vms, :vms
      #    end
      #
      #    generates:
      #
      #    def total_vms
      #      vms.count
      #    end
      #
      #    virtual_attribute :total_vms, :integer, :uses => :vms, :arel => ...
      #
      #   # arel == (SELECT COUNT(*) FROM vms where ems.id = vms.ems_id)
      #
      def virtual_total(name, relation, options = {})
        define_virtual_aggregate_attribute(name, relation, :count, Arel.star, options)
        define_method(name) { (has_attribute?(name) ? self[name] : send(relation).try(:size)) || 0 }
      end

      def virtual_sum(name, relation, column, options = {})
        define_virtual_aggregate_attribute(name, relation, :sum, column, options)
        define_virtual_aggregate_method(name, relation, column, :sum)
      end

      def virtual_minimum(name, relation, column, options = {})
        define_virtual_aggregate_attribute(name, relation, :minimum, column, options)
        define_virtual_aggregate_method(name, relation, column, :min, :minimum)
      end

      def virtual_maximum(name, relation, column, options = {})
        define_virtual_aggregate_attribute(name, relation, :maximum, column, options)
        define_virtual_aggregate_method(name, relation, column, :max, :maximum)
      end

      def virtual_average(name, relation, column, options = {})
        define_virtual_aggregate_attribute(name, relation, :average, column, options)
        define_virtual_aggregate_method(name, relation, column, :average) { |values| values.count == 0 ? 0 : values.sum / values.count }
      end

      def define_virtual_aggregate_attribute(name, relation, method_name, column, options)
        reflection = reflect_on_association(relation)

        if options.key?(:arel)
          arel = options.dup.delete(:arel)
          # if there is no relation to get to the arel, have to throw it away
          arel = nil if !arel || !reflection
        else
          arel = virtual_aggregate_arel(reflection, method_name, column)
        end

        if arel
          virtual_attribute name, :integer, :uses => options[:uses] || relation, :arel => arel
        else
          virtual_attribute name, :integer, **options
        end
      end

      def define_virtual_aggregate_method(name, relation, column, ruby_method_name, arel_method_name = ruby_method_name)
        define_method(name) do
          if has_attribute?(name)
            self[name] || 0
          elsif (rel = send(relation)).loaded?
            values = rel.map { |t| t.send(column) }.compact
            if block_given?
              yield values
            else
              values.blank? ? nil : values.send(ruby_method_name)
            end
          else
            rel.try(arel_method_name, column) || 0
          end
        end
      end

      def virtual_aggregate_arel(reflection, method_name, column)
        return unless reflection && [:has_many, :has_and_belongs_to_many].include?(reflection.macro)

        # need db access for the reflection join_keys, so delaying all this key lookup until call time
        lambda do |t|
          # strings and symbols are converted across, arel objects are not
          column = reflection.klass.arel_table[column] unless column.respond_to?(:count)

          # query: SELECT COUNT(*) FROM main_table JOIN foreign_table ON main_table.id = foreign_table.id JOIN ...
          relation_query   = joins(reflection.name).select(column.send(method_name))
          query            = relation_query.arel

          # algorithm:
          # - remove main_table from this sub query. (it is already in the primary query)
          # - move the foreign_table from the JOIN to the FROM clause
          # - move the main_table.id = foreign_table.id from the ON clause to the WHERE clause

          # query: SELECT COUNT(*) FROM main_table [ ] JOIN ...
          join = query.source.right.shift
          # query: SELECT COUNT(*) FROM [foreign_table] JOIN ...
          query.source.left = join.left
          # query: SELECT COUNT(*) FROM foreign_table JOIN ... [WHERE main_table.id = foreign_table.id]
          query.where(join.right.expr)

          # add coalesce to ensure correct value comes out
          t.grouping(Arel::Nodes::NamedFunction.new('COALESCE', [t.grouping(query), Arel::Nodes::SqlLiteral.new("0")]))
        end
      end
    end
  end
end

ActiveRecord::Base.include VirtualAttributes::VirtualTotal
