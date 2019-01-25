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

        def remove_virtual_fields(associations)
          case associations
          when String, Symbol
            virtual_field?(associations) ? nil : associations
          when Array
            associations.collect { |association| remove_virtual_fields(association) }.compact
          when Hash
            associations.each_with_object({}) do |(parent, child), h|
              next if virtual_field?(parent)
              reflection = reflect_on_association(parent.to_sym)
              h[parent] = reflection.options[:polymorphic] ? nil : reflection.klass.remove_virtual_fields(child) if reflection
            end
          else
            associations
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
      prepend Module.new {
        def preloaders_for_one(association, records, scope)
          klass_map = records.compact.group_by(&:class)

          loaders = klass_map.keys.group_by { |klass| klass.virtual_includes(association) }.flat_map do |virtuals, klasses|
            subset = klasses.flat_map { |klass| klass_map[klass] }
            preload(subset, virtuals)
          end

          records_with_association = klass_map.select { |k, rs| k.reflect_on_association(association) }.flat_map { |k, rs| rs }
          if records_with_association.any?
            loaders.concat(super(association, records_with_association, scope))
          end

          loaders
        end
      }
    end

    # FIXME: Hopefully we can get this into Rails core so this is no longer
    # required in our codebase, but the rule that are broken here are mostly
    # due to the style of the Rails codebase conflicting with our own.
    # Ignoring them to avoid noise in RuboCop, but allow us to keep the same
    # syntax from the original codebase.
    #
    # rubocop:disable Style/BlockDelimiters, Layout/SpaceAfterComma, Style/HashSyntax
    # rubocop:disable Layout/AlignHash, Metrics/AbcSize, Metrics/MethodLength
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
        #
        # This monkey patches the ActiveRecord::Associations::JoinDependency to
        # include columns into the main record that might have been added
        # through a `select` clause.
        #
        # This can be seen with the following:
        #
        #   Vm.select(Vm.arel_table[Arel.star]).select(:some_vm_virtual_col)
        #     .includes(:tags => {}).references(:tags => {})
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
        unless result_set.empty?
          join_dep_keys         = aliases.columns.map(&:right)
          join_root_aliases     = column_aliases.map(&:first)
          additional_attributes = result_set.first.keys
                                            .reject { |k| join_dep_keys.include?(k) }
                                            .reject { |k| join_root_aliases.include?(k) }
                                            .map    { |k| [k, k] }
          column_aliases += additional_attributes
        end
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
            construct(parent, join_root, row_hash, result_set, seen, model_cache, aliases)
          }
        end

        parents.values
      end
      # rubocop:enable Style/BlockDelimiters, Layout/SpaceAfterComma, Style/HashSyntax
      # rubocop:enable Layout/AlignHash, Metrics/AbcSize, Metrics/MethodLength
    end
  end

  class Relation
    def without_virtual_includes
      filtered_includes = includes_values && klass.remove_virtual_fields(includes_values)
      if filtered_includes != includes_values
        spawn.tap { |other| other.includes_values = filtered_includes }
      else
        self
      end
    end

    include(Module.new {
      # From ActiveRecord::FinderMethods
      def find_with_associations
        real = without_virtual_includes
        return super if real.equal?(self)

        if ActiveRecord.version.to_s >= "5.1"
          recs, join_dep = real.find_with_associations { |relation, join_dependency| [relation, join_dependency] }
        else
          recs = real.find_with_associations
        end
        MiqPreloader.preload(recs, preload_values + includes_values) if includes_values

        # when 5.0 support is dropped, assume a block given
        if block_given?
          yield recs, join_dep
        end
        recs
      end

      # From ActiveRecord::QueryMethods
      def select(*fields)
        return super if block_given? || fields.empty?
        # support virtual attributes by adding an alias to the sql phrase for the column
        # it does not add an as() if the column already has an as
        # this code is based upon _select()
        fields.flatten!
        fields.map! do |field|
          if virtual_attribute?(field) && (arel = klass.arel_attribute(field)) && arel.respond_to?(:as)
            arel.as(field.to_s)
          else
            field
          end
        end
        # end support virtual attributes
        super
      end

      # From ActiveRecord::Calculations
      def calculate(operation, attribute_name)
        # work around 1 until https://github.com/rails/rails/pull/25304 gets merged
        # This allows attribute_name to be a virtual_attribute
        if (arel = klass.arel_attribute(attribute_name)) && virtual_attribute?(attribute_name)
          attribute_name = arel
        end
        # end work around 1

        # allow calculate to work when including a virtual attribute
        real = without_virtual_includes
        return super if real.equal?(self)

        real.calculate(operation, attribute_name)
      end
    })
  end
end
