module ActiveRecord
  module VirtualAttributes
    # VirtualIncludes associates an includes with an attribute
    #
    # Model.virtual_attribute :field, :string, :includes => :table
    # Model.includes(:field)
    #
    # is equivalent to:
    #
    # Model.includes(:table)
    module VirtualIncludes
      extend ActiveSupport::Concern

      included do
        class_attribute :_virtual_includes, :instance_accessor => false
        self._virtual_includes = {}
      end

      module ClassMethods
        def virtual_includes(name)
          _virtual_includes[name.to_s]
        end

        private

        def define_virtual_include(name, uses)
          self._virtual_includes = _virtual_includes.merge(name.to_s => uses) unless uses.nil?
        end
      end
    end
  end
end
