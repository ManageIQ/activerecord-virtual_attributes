require "active_record"
module ActiveRecord
  class Base
    def self.virtual_total(name, *_)
      define_method(name) {}
    end

    def self.virtual_aggregate(*_)
    end

    def self.virtual_has_many(*_)
    end

    def self.virtual_has_one(*_)
    end

    def self.virtual_attribute(*_)
    end

    def self.virtual_delegate(*_)
    end
  end
end

module VirtualFields
end
