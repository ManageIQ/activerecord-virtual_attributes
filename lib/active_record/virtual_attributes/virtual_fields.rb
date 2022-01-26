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
              if reflection.nil?
                merge_includes(h, parent)
              elsif reflection.options[:polymorphic]
                merge_includes(h, parent => child)
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
        # preloader.rb active record 6.0
        # changed:
        # since grouped_records can return a hash/array, we need to handle those 2 new cases
        def preloaders_for_reflection(reflection, records, scope, polymorphic_parent)
          case reflection
          when Array
            reflection.flat_map { |ref| preloaders_on(ref, records, scope, polymorphic_parent) }
          when Hash
            preloaders_on(reflection, records, scope, polymorphic_parent)
          else
            super(reflection, records, scope)
          end
        end

        # rubocop:disable Style/BlockDelimiters, Lint/AmbiguousBlockAssociation, Style/MethodCallWithArgsParentheses
        # preloader.rb active record 6.0
        # changed:
        # passing polymorphic around (and makes 5.2 more similar to 6.0)
        def preloaders_for_hash(association, records, scope, polymorphic_parent)
          association.flat_map { |parent, child|
            grouped_records(parent, records, polymorphic_parent).flat_map do |reflection, reflection_records|
              loaders = preloaders_for_reflection(reflection, reflection_records, scope, polymorphic_parent)
              recs = loaders.flat_map(&:preloaded_records).uniq
              child_polymorphic_parent = reflection && reflection.respond_to?(:options) && reflection.options[:polymorphic]
              loaders.concat Array.wrap(child).flat_map { |assoc|
                preloaders_on assoc, recs, scope, child_polymorphic_parent
              }
              loaders
            end
          }
        end

        # preloader.rb active record 6.0
        # changed:
        # passing polymorphic_parent to preloaders_for_reflection
        def preloaders_for_one(association, records, scope, polymorphic_parent)
          grouped_records(association, records, polymorphic_parent)
            .flat_map do |reflection, reflection_records|
              preloaders_for_reflection(reflection, reflection_records, scope, polymorphic_parent)
            end
        end

        # preloader.rb active record 6.0, 6.1
        def grouped_records(orig_association, records, polymorphic_parent)
          h = {}
          records.each do |record|
            # The virtual_field lookup can return Symbol/Nil/Other (typically a Hash)
            #   so the case statement and the cases for Nil/Other are new

            # each class can resolve virtual_{attributes,includes} differently
            association = record.class.replace_virtual_fields(orig_association)
            # 1 line optimization for single element array:
            association = association.first if association.kind_of?(Array) && association.size == 1

            case association
            when Symbol, String
              reflection = record.class._reflect_on_association(association)
              next if polymorphic_parent && !reflection || !record.association(association).klass
            when nil
              next
            else # need parent (preloaders_for_{hash,one}) to handle this Array/Hash
              reflection = association
            end
            (h[reflection] ||= []) << record
          end
          h
        end
        # rubocop:enable Style/BlockDelimiters, Lint/AmbiguousBlockAssociation, Style/MethodCallWithArgsParentheses
      })
    end

    if ActiveRecord.version.to_s < "6.1"
      # FIXME: Hopefully we can get this into Rails core so this is no longer
      # required in our codebase, but the rule that are broken here are mostly
      # due to the style of the Rails codebase conflicting with our own.
      # Ignoring them to avoid noise in RuboCop, but allow us to keep the same
      # syntax from the original codebase.
      #
      # rubocop:disable Style/BlockDelimiters, Layout/SpaceAfterComma, Style/HashSyntax
      # rubocop:disable Layout/HashAlignment
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
              construct(parent, join_root, row_hash, seen, model_cache)
            }
          end

          parents.values
        end
        # rubocop:enable Style/BlockDelimiters, Layout/SpaceAfterComma, Style/HashSyntax
        # rubocop:enable Layout/HashAlignment

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
        # columns for both of the tables together to do it.  Unfortunately (or
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
          additional_attributes.map { |k| Aliases::Column.new(k, k) }
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
      def apply_join_dependency(*args, **kargs, &block)
        real = without_virtual_includes
        if real.equal?(self)
          super
        else
          real.apply_join_dependency(*args, **kargs, &block)
        end
      end

      # From ActiveRecord::QueryMethods (rails 5.2 - 6.1)
      def build_select(arel)
        if select_values.any?
          cols = arel_columns(select_values.uniq).map do |col|
            # if it is a virtual attribute, then add aliases to those columns
            if col.kind_of?(Arel::Nodes::Grouping) && col.name
              col.as(connection.quote_column_name(col.name))
            else
              col
            end
          end
          arel.project(*cols)
        else
          super
        end
      end

      # from ActiveRecord::QueryMethods (rails 5.2 - 6.0)
      def arel_column(field, &block)
        if virtual_attribute?(field) && (arel = table[field])
          arel
        else
          super
        end
      end

      # From ActiveRecord::QueryMethods
      # introduces virtual includes support for left joins
      if ActiveRecord.version.to_s < "6.1"
        def build_left_outer_joins(manager, outer_joins, *rest)
          outer_joins = klass.replace_virtual_fields(outer_joins)
          super if outer_joins.present?
        end
      else
        def construct_join_dependency(associations, join_type) # :nodoc:
          associations = klass.replace_virtual_fields(associations)
          super
        end
      end

      # From ActiveRecord::Calculations
      # introduces virtual includes support for calculate (we mostly use COUNT(*))
      def calculate(operation, attribute_name)
        # allow calculate to work with includes and a virtual attribute
        real = without_virtual_includes
        return super if real.equal?(self)

        real.calculate(operation, attribute_name)
      end
    })
  end
end
