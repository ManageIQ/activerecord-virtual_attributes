module ActiveRecord
  module VirtualAttributes
    module VirtualFields
      extend ActiveSupport::Concern
      include ActiveRecord::VirtualAttributes
      include ActiveRecord::VirtualAttributes::VirtualReflections

      module NonARModels
        def dangerous_attribute_method?(_); false; end

        def generated_association_methods; self; end

        def add_autosave_association_callbacks(*_args); self; end

        def belongs_to_required_by_default; false; end
      end

      included do
        unless respond_to?(:dangerous_attribute_method?)
          extend NonARModels
        end
      end

      module ClassMethods
        def virtual_fields_base?
          !(superclass < VirtualFields)
        end

        def virtual_field?(name)
          virtual_attribute?(name) || virtual_reflection?(name)
        end

        def replace_virtual_fields(associations)
          return associations if associations.blank?

          case associations
          when String, Symbol
            virtual_field?(associations) ? replace_virtual_fields(virtual_includes(associations)) : associations
          when Array
            associations.collect { |association| replace_virtual_fields(association) }.compact
          when Hash
            replace_virtual_field_hash(associations)
          else
            associations
          end
        end

        def replace_virtual_field_hash(associations)
          associations.each_with_object({}) do |(parent, child), h|
            if virtual_field?(parent) # form virtual_attribute => {}
              merge_includes(h, replace_virtual_fields(virtual_includes(parent)))
            else
              reflection = reflect_on_association(parent.to_sym)
              if reflection.nil? || reflection.options[:polymorphic]
                merge_includes(h, parent)
              else
                merge_includes(h, parent => reflection.klass.replace_virtual_fields(child) || {})
              end
            end
          end
        end

        # @param [Hash, Array, String, Symbol] value
        # @return [Hash]
        def include_to_hash(value)
          case value
          when String, Symbol
            {value => {}}
          when Array
            value.flatten.each_with_object({}) { |k, h| h[k] = {} }
          when nil
            {}
          else
            value
          end
        end

        # @param [Hash] hash1
        # @param [Hash] hash2
        def merge_includes(hash1, hash2)
          return hash1 if hash2.blank?

          hash1 = include_to_hash(hash1)
          hash2 = include_to_hash(hash2)
          hash1.deep_merge!(hash2) do |_k, v1, v2|
            merge_includes(v1, v2)
          end
        end
      end
    end
  end
end

module ActiveRecord
  class Base
    include ActiveRecord::VirtualAttributes::VirtualFields
  end

  module Associations
    class Preloader
      prepend(Module.new {
        def preloaders_for_one(association, records, scope)
          klass_map = records.compact.group_by(&:class)

          loaders = klass_map.keys.group_by { |klass| klass.virtual_includes(association) }.flat_map do |virtuals, klasses|
            subset = klasses.flat_map { |klass| klass_map[klass] }
            preload(subset, virtuals)
          end

          records_with_association = klass_map.select { |k, _rs| k.reflect_on_association(association) }.flat_map { |_k, rs| rs }
          if records_with_association.any?
            loaders.concat(super(association, records_with_association, scope))
          end

          loaders
        end
      })
    end

    # FIXME: Hopefully we can get this into Rails core so this is no longer
    # required in our codebase, but the rule that are broken here are mostly
    # due to the style of the Rails codebase conflicting with our own.
    # Ignoring them to avoid noise in RuboCop, but allow us to keep the same
    # syntax from the original codebase.
    #
    # rubocop:disable Style/BlockDelimiters, Layout/SpaceAfterComma, Style/HashSyntax
    # rubocop:disable Layout/AlignHash
    class JoinDependency
      def instantiate(result_set, *_, &block)
        primary_key = aliases.column_alias(join_root, join_root.primary_key)

        seen = Hash.new { |i, object_id|
          i[object_id] = Hash.new { |j, child_class|
            j[child_class] = {}
          }
        }

        model_cache = Hash.new { |h,klass| h[klass] = {} }
        parents = model_cache[join_root]
        column_aliases = aliases.column_aliases(join_root)

        # New Code
        column_aliases += select_values_from_references(column_aliases, result_set) if result_set.present?
        # End of New Code

        message_bus = ActiveSupport::Notifications.instrumenter

        payload = {
          record_count: result_set.length,
          class_name: join_root.base_klass.name
        }

        message_bus.instrument('instantiation.active_record', payload) do
          result_set.each { |row_hash|
            parent_key = primary_key ? row_hash[primary_key] : row_hash
            parent = parents[parent_key] ||= join_root.instantiate(row_hash, column_aliases, &block)
            if ActiveRecord.version.to_s < "6.0"
              construct(parent, join_root, row_hash, result_set, seen, model_cache, aliases)
            else
              construct(parent, join_root, row_hash, seen, model_cache)
            end
          }
        end

        parents.values
      end
      # rubocop:enable Style/BlockDelimiters, Layout/SpaceAfterComma, Style/HashSyntax
      # rubocop:enable Layout/AlignHash

      #
      # This monkey patches the ActiveRecord::Associations::JoinDependency to
      # include columns into the main record that might have been added
      # through a `select` clause.
      #
      # This can be seen with the following:
      #
      #   Vm.select(Vm.arel_table[Arel.star]).select(:some_vm_virtual_col)
      #     .includes(:tags => {}).references(:tags)
      #
      # Which will produce a SQL SELECT statement kind of like this:
      #
      #   SELECT "vms".*,
      #          (<virtual_attribute_arel>) AS some_vm_virtual_col,
      #          "vms"."id"      AS t0_r0
      #          "vms"."vendor"  AS t0_r1
      #          "vms"."format"  AS t0_r1
      #          "vms"."version" AS t0_r1
      #          ...
      #          "tags"."id"     AS t1_r0
      #          "tags"."name"   AS t1_r1
      #
      # This is because rails is trying to reduce the number of queries
      # needed to fetch all of the records in the include, so it grabs the
      # columns for both of the tables together to do it.  Unfortuantely (or
      # fortunately... depending on how you look at it), it does not remove
      # any `.select` columns from the query that is run in the process, so
      # that is brought along for the ride, but never used when this method
      # instanciates the objects.
      #
      # The "New Code" here simply also instanciates any extra rows that
      # might have been included in the select (virtual_columns) as well and
      # brought back with the result set.
      def select_values_from_references(column_aliases, result_set)
        join_dep_keys         = aliases.columns.map(&:right)
        join_root_aliases     = column_aliases.map(&:first)
        additional_attributes = result_set.first.keys
                                          .reject { |k| join_dep_keys.include?(k) }
                                          .reject { |k| join_root_aliases.include?(k) }
        if ActiveRecord.version.to_s >= "6.0"
          additional_attributes.map { |k| Aliases::Column.new(k, k) }
        else
          additional_attributes.map { |k| [k, k] }
        end
      end
    end
  end

  class Relation
    def without_virtual_includes
      filtered_includes = includes_values && klass.replace_virtual_fields(includes_values)
      if filtered_includes != includes_values
        spawn.tap { |other| other.includes_values = filtered_includes }
      else
        self
      end
    end

    include(Module.new {
      # From ActiveRecord::FinderMethods
      if ActiveRecord.version.to_s >= "5.2"
        def apply_join_dependency(*args, &block)
          real = without_virtual_includes
          if real.equal?(self)
            super
          else
            real.apply_join_dependency(*args, &block)
          end
        end
      else
        def find_with_associations(&block)
          real = without_virtual_includes
          if real.equal?(self)
            super
          else
            real.find_with_associations(&block)
          end
        end
      end

      # From ActiveRecord::QueryMethods (rails 5.2 - 6.0)
      def build_select(arel)
        if select_values.any?
          arel.project(*arel_columns(select_values.uniq, true))
        elsif klass.ignored_columns.any?
          arel.project(*klass.column_names.map { |field| arel_attribute(field) })
        else
          arel.project(table[Arel.star])
        end
      end

      # from ActiveRecord::QueryMethods (rails 5.2 - 6.0)
      def arel_columns(columns, allow_alias = false)
        columns.flat_map do |field|
          case field
          when Symbol
            arel_column(field.to_s, allow_alias) do |attr_name|
              connection.quote_table_name(attr_name)
            end
          when String
            arel_column(field, allow_alias, &:itself)
          when Proc
            field.call
          else
            field
          end
        end
      end

      # from ActiveRecord::QueryMethods (rails 5.2 - 6.0)
      def arel_column(field, allow_alias = false, &block)
        field = klass.attribute_aliases[field] || field
        from = from_clause.name || from_clause.value

        if klass.columns_hash.key?(field) && (!from || table_name_matches?(from))
          arel_attribute(field)
        elsif virtual_attribute?(field)
          virtual_attribute_arel_column(field, allow_alias, &block)
        else
          yield field
        end
      end

      def virtual_attribute_arel_column(field, allow_alias)
        arel = arel_attribute(field)
        if arel.nil?
          yield field
        elsif allow_alias && arel && arel.respond_to?(:as) && !arel.kind_of?(Arel::Nodes::As) && !arel.try(:alias)
          arel.as(connection.quote_column_name(field.to_s))
        else
          arel
        end
      end

      # From ActiveRecord::QueryMethods
      def table_name_matches?(from)
        /(?:\A|(?<!FROM)\s)(?:\b#{table.name}\b|#{connection.quote_table_name(table.name)})(?!\.)/i.match?(from.to_s)
      end

      # From ActiveRecord::QueryMethods
      def build_left_outer_joins(manager, outer_joins, *rest)
        outer_joins = klass.replace_virtual_fields(outer_joins)
        super if outer_joins.present?
      end

      # From ActiveRecord::Calculations
      def calculate(operation, attribute_name)
        if ActiveRecord.version.to_s < "5.1"
          if (arel = klass.arel_attribute(attribute_name)) && virtual_attribute?(attribute_name)
            attribute_name = arel
          end
        end

        # allow calculate to work with includes and a virtual attribute
        real = without_virtual_includes
        return super if real.equal?(self)

        real.calculate(operation, attribute_name)
      end
    })
  end
end
