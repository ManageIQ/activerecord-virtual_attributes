module ActiveRecord
  module VirtualAttributes
    module VirtualIncludes
      extend ActiveSupport::Concern

      included do
        class_attribute :_virtual_includes, :instance_accessor => false
        self._virtual_includes = {}
      end

      module ClassMethods
        def virtual_includes(name)
          load_schema
          _virtual_includes[name.to_s]
        end

        private

        def define_virtual_include(name, uses)
          self._virtual_includes = _virtual_includes.merge(name => uses)
        end
      end
    end
  end
end
