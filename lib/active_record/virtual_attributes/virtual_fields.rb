module ActiveRecord
  module VirtualAttributes
    module VirtualFields
      extend ActiveSupport::Concern
      include ActiveRecord::VirtualAttributes
      include ActiveRecord::VirtualAttributes::VirtualReflections

      # rubocop:disable Style/SingleLineMethods
      module NonARModels
        def dangerous_attribute_method?(_); false; end

        def generated_association_methods; self; end

        def add_autosave_association_callbacks(*_args); self; end

        def belongs_to_required_by_default; false; end
      end
      # rubocop:enable Style/SingleLineMethods

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
          return nil if associations.blank?

          ret =
            case associations
            when String, Symbol
              virtual_field?(associations) ? replace_virtual_fields(virtual_includes(associations)) : associations.to_sym
            when Array
              associations.filter_map { |association| replace_virtual_fields(association) }
            when Hash
              replace_virtual_field_hash(associations)
            else
              associations
            end
          simplify_includes(ret)
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
            {value.to_sym => {}}
          when Array
            value.flatten.each_with_object({}) do |k, h|
              merge_includes(h, k)
            end
          when nil
            {}
          else
            value
          end
        end

        # @param [Hash] hash1 (incoming hash is modified and returned)
        # @param [Hash|Symbol|nil] hash2 (this hash will not be modified)
        def merge_includes(hash1, hash2)
          return hash1 if hash2.blank?

          # very common case.
          # optimization to skip deep_merge and hash creation
          if hash2.kind_of?(Symbol)
            hash1[hash2] ||= {}
            return hash1
          end

          hash1.deep_merge!(include_to_hash(hash2)) do |_k, v1, v2|
            # this block is conflict resolution when a key has 2 values
            merge_includes(include_to_hash(v1), v2)
          end
        end

        # @param [Hash|Array|Symbol|nil]
        def simplify_includes(ret)
          case ret
          when Hash
            ret.size <= 1 && ret.values.first.blank? ? ret.keys.first : ret
          when Array
            ret.size <= 1 ? ret.first : ret
          else
            ret
          end
        end
      end
    end
  end
end

def assert_klass_has_instance_method(klass, instance_method)
  klass.instance_method(instance_method)
rescue NameError => err
  msg = "#{klass} is missing the method our prepended code is expecting to patch. Was the undefined method removed or renamed upstream?\nSee: #{__FILE__}.\nThe NameError was: #{err}. "
  raise NameError, msg
end

# Expect these methods to exist. (Otherwise we are patching the wrong methods)
%w[
  grouped_records
  preloaders_for_reflection
].each { |method| assert_klass_has_instance_method(ActiveRecord::Associations::Preloader::Branch, method) }

%w[
  build_select
  arel_column
  construct_join_dependency
].each { |method| assert_klass_has_instance_method(ActiveRecord::Relation, method) }

module ActiveRecord
  class Base
    include ActiveRecord::VirtualAttributes::VirtualFields
  end

  module Associations
    class Preloader
      prepend(Module.new do
        # preloader is called with virtual attributes - need to resolve
        def call
          # Possibly overkill since all records probably have the same class and associations
          # use a cache so we only convert includes once per base class
          assoc_cache = Hash.new { |h, klass| h[klass] = klass.replace_virtual_fields(associations) }

          # convert the includes with virtual attributes to includes with proper associations
          records_by_assoc = records.group_by { |rec| assoc_cache[rec.class] }
          # If the association were already translated, then short circuit / do the standard preloader work.
          # When replace_virtual_fields removes the outer array, match that too.
          if records_by_assoc.size == 1 &&
            (associations == records_by_assoc.keys.first || associations == [records_by_assoc.keys.first])
            return super
          end

          # for each of the associations, run a preloader
          records_by_assoc.each do |klass_associations, klass_records|
            next if klass_associations.blank?

            Array.wrap(klass_associations).each do |klass_association|
              # this calls back into itself, but it will take the short circuit
              Preloader.new(:records => klass_records, :associations => klass_association, :scope => scope, :available_records => @available_records, :associate_by_default => @associate_by_default).call
            end
          end
        end
      end)

      class Branch
        prepend(Module.new do
          # from branched.rb 7.0
          # not going to modify rails code for rubocops
          # rubocop:disable Lint/AmbiguousOperatorPrecedence
          # rubocop:disable Layout/EmptyLineAfterGuardClause
          def grouped_records
            h = {}
            polymorphic_parent = !root? && parent.polymorphic?
            source_records.each do |record|
              # begin virtual_attributes changes
              association = record.class.replace_virtual_fields(self.association)
              # end virtual_attributes changes

              reflection = record.class._reflect_on_association(association)
              next if polymorphic_parent && !reflection || !record.association(association).klass
              (h[reflection] ||= []) << record
            end
            h
          end
          # rubocop:enable Layout/EmptyLineAfterGuardClause
          # rubocop:enable Lint/AmbiguousOperatorPrecedence

          # branched.rb 7.0
          # rubocop:disable Style/MultilineBlockChain
          def preloaders_for_reflection(reflection, reflection_records)
            reflection_records.group_by do |record|
              # begin virtual_attributes changes
              needed_association = record.class.replace_virtual_fields(association)
              # end virtual_attributes changes

              klass = record.association(needed_association).klass

              if reflection.scope && reflection.scope.arity != 0
                # For instance dependent scopes, the scope is potentially
                # different for each record. To allow this we'll group each
                # object separately into its own preloader
                reflection_scope = reflection.join_scopes(klass.arel_table, klass.predicate_builder, klass, record).inject(&:merge!)
              end

              [klass, reflection_scope]
            end.map do |(rhs_klass, reflection_scope), rs|
              preloader_for(reflection).new(rhs_klass, rs, reflection, scope, reflection_scope, associate_by_default)
            end
          end
        end)
        # rubocop:enable Style/MultilineBlockChain
      end
    end
  end

  class Relation
    include(Module.new do
      # From ActiveRecord::QueryMethods (rails 5.2 - 6.1)
      def build_select(arel)
        if select_values.any?
          cols = arel_columns(select_values).map do |col|
            # if it is a virtual attribute, then add aliases to those columns
            if col.kind_of?(VirtualAttributes::VirtualAttribute)
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

      # from ActiveRecord::QueryMethods (rails 5.2 - 7.0)
      def arel_column(field)
        if virtual_attribute?(field) && (arel = table[field])
          arel
        else
          super
        end
      end

      def construct_join_dependency(associations, join_type) # :nodoc:
        associations = klass.replace_virtual_fields(associations) || {}
        super
      end
    end)
  end
end
