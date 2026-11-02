require "active_support/concern"
require "active_record"

require "active_record/virtual_attributes/version"
require "active_record/virtual_attributes/virtual_includes"
require "active_record/virtual_attributes/virtual_arel"
require "active_record/virtual_attributes/virtual_delegates"

module ActiveRecord
  module VirtualAttributes
    extend ActiveSupport::Concern
    include ActiveRecord::VirtualAttributes::VirtualIncludes
    include ActiveRecord::VirtualAttributes::VirtualArel
    include ActiveRecord::VirtualAttributes::VirtualDelegates

    module Type
      # TODO: do we actually need symbol types?
      class Symbol < ActiveRecord::Type::String
        def type
          :symbol
        end
      end

      class StringSet < ActiveRecord::Type::Value
        def type
          :string_set
        end
      end

      class NumericSet < ActiveRecord::Type::Value
        def type
          :numeric_set
        end
      end
    end

    ActiveRecord::Type.register(:numeric_set, Type::NumericSet)
    ActiveRecord::Type.register(:string_set, Type::StringSet)
    ActiveRecord::Type.register(:symbol, Type::Symbol)

    def self.deprecator
      @deprecator ||= ActiveSupport::Deprecation.new(ActiveRecord::VirtualAttributes::VERSION, "virtual_attributes")
    end

    included do
      class_attribute :virtual_attributes_to_define, :instance_accessor => false, :default => {}
    end

    module ClassMethods
      #
      # Definition
      #

      # Compatibility method: `virtual_attribute` is a more accurate name
      def virtual_column(name, type:, **options)
        virtual_attribute(name, type, **options)
      end

      def virtual_attribute(name, type, through: nil, uses: nil, arel: nil, source: name, default: nil, **options, &block)
        name = name.to_s
        reload_schema_from_cache

        self.virtual_attributes_to_define =
          virtual_attributes_to_define.merge(name => [type, options])

        if through
          define_delegate(name, source, :to => through, :allow_nil => true, :default => default)

          unless (to_ref = reflection_with_virtual(through))
            raise ArgumentError, "#{self.name}.virtual_attribute #{name.inspect} references unknown :through association #{through.inspect}"
          end

          # ensure that the through table is in the uses clause
          uses = merge_includes({through => {}}, uses)

          # We can not validate target#source exists
          #   Because we may not have loaded the class yet
          #   And we definitely have not loaded the database yet
          arel ||= virtual_delegate_arel(source, to_ref)
        elsif block_given?
          define_method(name) do
            has_attribute?(name) ? self[name] : instance_eval(&block)
          end
        end

        define_virtual_include(name, uses)
        define_virtual_arel(name, arel)
      end

      #
      # Introspection
      #

      def virtual_attribute?(name)
        has_attribute?(name) && (
          !respond_to?(:column_for_attribute) ||
          column_for_attribute(name).kind_of?(ActiveRecord::ConnectionAdapters::NullColumn)
        )
      end

      def virtual_attribute_names
        if respond_to?(:column_names)
          attribute_names - column_names
        else
          attribute_names
        end
      end

      def attribute_types
        @attribute_types || super.tap do |hash|
          virtual_attributes_to_define.each do |name, (type, options)|
            type = type.call if type.respond_to?(:call)
            type = ActiveRecord::Type.lookup(type, **options) if type.kind_of?(Symbol)
            hash[name] = type
          end
        end
      end

      def define_virtual_attribute(name, cast_type)
        attribute_types[name.to_s] = cast_type
      end
    end
  end
end
require "active_record/virtual_attributes/virtual_reflections"
require "active_record/virtual_attributes/virtual_fields"

#
# Class extensions
#

require "active_record/virtual_attributes/virtual_total"

# legacy support for sql types
module VirtualAttributes
  module Type
    Symbol      = ActiveRecord::VirtualAttributes::Type::Symbol
    StringSet   = ActiveRecord::VirtualAttributes::Type::StringSet
    NumericSet  = ActiveRecord::VirtualAttributes::Type::NumericSet
  end
end
