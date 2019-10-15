module VirtualAttributes
  module VirtualTotal
    extend ActiveSupport::Concern

    module ClassMethods
      private

      # define an attribute to calculating the total of a has many relationship
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
        define_virtual_size_method(name, relation)
        define_virtual_aggregate_attribute(name, relation, :size, nil, options)
      end

      # define an attribute to calculate the sum of a has may relationship
      #
      #  example:
      #
      #    class Hardware
      #      has_many :disks
      #      virtual_aggregate :allocated_disk_storage, :disks, :sum, :size
      #    end
      #
      #    generates:
      #
      #    def allocated_disk_storage
      #      if disks.loaded?
      #        disks.blank? ? nil : disks.map { |t| t.size.to_i }.sum
      #      else
      #        disks.sum(:size) || 0
      #      end
      #    end
      #
      #    virtual_attribute :allocated_disk_storage, :integer, :uses => :disks, :arel => ...
      #
      #    # arel => (SELECT sum("disks"."size") where "hardware"."id" = "disks"."hardware_id")

      def virtual_aggregate(name, relation, method_name = :sum, column = nil, options = {})
        return define_virtual_total(name, relation, options) if method_name == :size

        define_virtual_aggregate_method(name, relation, method_name, column)
        define_virtual_aggregate_attribute(name, relation, method_name, column, options)
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

      def define_virtual_size_method(name, relation)
        define_method(name) do
          (attribute_present?(name) ? self[name] : nil) || send(relation).try(:size) || 0
        end
      end

      def define_virtual_aggregate_method(name, relation, method_name, column)
        define_method(name) do
          (attribute_present?(name) ? self[name] : nil) ||
            begin
              rel = send(relation)
              if rel.loaded?
                rel.blank? ? nil : (rel.map { |t| t.send(column).to_i } || 0).send(method_name)
              else
                rel.try(method_name, column) || 0
              end
            end
        end
      end

      def virtual_aggregate_arel(reflection, method_name, column)
        return unless reflection && reflection.macro == :has_many

        # need db access for the reflection join_keys, so delaying all this key lookup until call time
        lambda do |t|
          # arel_column: COUNT(*)
          arel_column = if method_name == :size
                          Arel.star.count
                        else
                          reflection.klass.arel_attribute(column).send(method_name)
                        end

          # query: SELECT COUNT(*) FROM main_table JOIN foreign_table ON main_table.id = foreign_table.id JOIN ...
          relation_query   = joins(reflection.name).select(arel_column)
          query            = relation_query.arel
          bound_attributes = relation_query.bound_attributes

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

          # convert bind variables from ? to actual values. otherwise, sql is incomplete
          conn = connection
          sql  = conn.unprepared_statement { conn.to_sql(query, bound_attributes) }

          # add () around query
          t.grouping(Arel::Nodes::SqlLiteral.new(sql))
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, VirtualAttributes::VirtualTotal)
