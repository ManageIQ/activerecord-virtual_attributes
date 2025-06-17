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
      def virtual_column(name, **options)
        type = options.delete(:type)
        raise ArgumentError, "missing :type attribute" unless type

        virtual_attribute(name, type, **options)
      end

      def virtual_attribute(name, type, **options)
        name = name.to_s
        reload_schema_from_cache

        self.virtual_attributes_to_define =
          virtual_attributes_to_define.merge(name => [type, options])
      end

      #
      # Introspection
      #

      def virtual_attribute?(name)
        load_schema
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

      private

      def load_schema!
        super

        virtual_attributes_to_define.each do |name, (type, options)|
          type = type.call if type.respond_to?(:call)
          type = ActiveRecord::Type.lookup(type, **options.except(:uses, :arel)) if type.kind_of?(Symbol)

          define_virtual_attribute(name, type, **options.slice(:uses, :arel))
        end

        virtual_delegates_to_define.each do |method_name, (method, options)|
          define_virtual_delegate(method_name, method, options)
        end
      end

      def define_virtual_attribute(name, cast_type, uses: nil, arel: nil)
        attribute_types[name] = cast_type
        define_virtual_include(name, uses) if uses
        define_virtual_arel(name, arel) if arel
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
