require 'active_record'

##
# Creates a database schema for the test, in memory, builds up models, and
# removes them once finished.
#
# Example:
#
#  ```
#  describe "Book#where", :with_test_class
#  end
#  ```
#
RSpec.shared_context 'with test_class', :with_test_class do
  before do
    class TestClassBase < ActiveRecord::Base
      self.abstract_class = true

      include VirtualFields
    end

    ActiveRecord::Schema.define do
      # rails method - can't do anything about this name
      def self.set_pk_sequence!(*)
      end

      self.verbose = false

      create_table :test_classes, :force => true do |t|
        t.integer :col1
        t.string  :str
      end

      create_table :test_other_classes, :force => true do |t|
        t.integer :ocol1
        t.string  :ostr
      end
    end

    class TestClass < TestClassBase
      belongs_to :ref1, :class_name => 'TestClass', :foreign_key => :col1
    end
  end

  after do
    Object.send(:remove_const, :TestClass)
    Object.send(:remove_const, :TestClassBase)
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'with test_class',
                        :with_test_class => true
end
