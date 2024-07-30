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

if ActiveRecord.version >= Gem::Version.new(7.0) # Rails 7.0 expected methods to patch
  %w[
    grouped_records
  ].each { |method| assert_klass_has_instance_method(ActiveRecord::Associations::Preloader::Branch, method) }
elsif ActiveRecord.version >= Gem::Version.new(6.1) # Rails 6.1 methods to patch
  %w[
    preloaders_for_reflection
    preloaders_for_hash
    preloaders_for_one
    grouped_records
  ].each { |method| assert_klass_has_instance_method(ActiveRecord::Associations::Preloader, method) }
end

# Expected methods to patch on any version
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
      class Branch
        prepend(Module.new {
          # from branched.rb 7.0
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
        })
      end if ActiveRecord.version >= Gem::Version.new(7.0)
    end
  end

  class Relation
    include(Module.new {
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
    })
  end
end
