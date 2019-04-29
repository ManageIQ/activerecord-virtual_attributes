require "active_support/concern"
require "active_record"

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

    included do
      class_attribute :virtual_attributes_to_define, :instance_accessor => false
      self.virtual_attributes_to_define = {}
    end

    module ClassMethods
      #
      # Definition
      #

      # Compatibility method: `virtual_attribute` is a more accurate name
      def virtual_column(name, type_or_options, **options)
        if type_or_options.kind_of?(Hash)
          options = options.merge(type_or_options)
          type = options.delete(:type)
        else
          type = type_or_options
        end

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

      def attributes_builder # :nodoc:
        unless defined?(@attributes_builder) && @attributes_builder
          defaults = _default_attributes.except(*(column_names - [primary_key]))
          # change necessary for rails 5.0 and 5.1 - (changed/introduced in https://github.com/rails/rails/pull/31894)
          defaults = defaults.except(*virtual_attribute_names)
          # end change
          @attributes_builder = if ActiveRecord.version.to_s >= "5.2"
                                  ActiveModel::AttributeSet::Builder.new(attribute_types, defaults)
                                else
                                  ActiveRecord::AttributeSet::Builder.new(attribute_types, defaults)
                                end
        end
        @attributes_builder
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

# this patch is no longer necessary for 5.2
if ActiveRecord.version.to_s < "5.2"
  require "active_record/attribute"
  module ActiveRecord
    # This is a bug in rails 5.0 and 5.1, but it is made much worse by virtual attributes
    class Attribute
      def with_value_from_database(value)
        # self.class.from_database(name, value, type)
        initialized? ? self.class.from_database(name, value, type) : self
      end
    end
  end
end

require "active_record/virtual_attributes/virtual_total"
require "active_record/virtual_attributes/arel_groups"

# legacy support for sql types
module VirtualAttributes
  module Type
    Symbol      = ActiveRecord::VirtualAttributes::Type::Symbol
    StringSet   = ActiveRecord::VirtualAttributes::Type::StringSet
    NumericSet  = ActiveRecord::VirtualAttributes::Type::NumericSet
  end
end
