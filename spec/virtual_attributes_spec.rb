RSpec.describe ActiveRecord::VirtualAttributes::VirtualFields do
  context "TestClass", :with_test_class do
    it "should not have any virtual columns" do
      expect(TestClass.virtual_attribute_names).to be_empty

      expect(TestClass.attribute_names).to eq(TestClass.column_names)
    end

    context ".virtual_column" do
      it "with invalid parameters" do
        expect { TestClass.virtual_column :vcol1 }.to raise_error(ArgumentError)
      end

      it "with symbol name" do
        TestClass.virtual_column :vcol1, :type => :string
        expect(TestClass.attribute_names).to include("vcol1")
      end

      it "with string name" do
        TestClass.virtual_column "vcol1", :type => :string
        expect(TestClass.attribute_names).to include("vcol1")
      end

      it "with string type" do
        TestClass.virtual_column :vcol1, :type => :string
        expect(TestClass.type_for_attribute("vcol1")).to be_kind_of(ActiveModel::Type::String)
        expect(TestClass.type_for_attribute("vcol1").type).to eq(:string)
      end

      it "with symbol type" do
        TestClass.virtual_column :vcol1, :type => :symbol
        expect(TestClass.type_for_attribute("vcol1")).to be_kind_of(ActiveRecord::VirtualAttributes::Type::Symbol)
        expect(TestClass.type_for_attribute("vcol1").type).to eq(:symbol)
      end

      it "with string_set type" do
        TestClass.virtual_column :vcol1, :type => :string_set
        expect(TestClass.type_for_attribute("vcol1")).to be_kind_of(ActiveRecord::VirtualAttributes::Type::StringSet)
        expect(TestClass.type_for_attribute("vcol1").type).to eq(:string_set)
      end

      it "with numeric_set type" do
        TestClass.virtual_column :vcol1, :type => :numeric_set
        expect(TestClass.type_for_attribute("vcol1")).to be_kind_of(ActiveRecord::VirtualAttributes::Type::NumericSet)
        expect(TestClass.type_for_attribute("vcol1").type).to eq(:numeric_set)
      end

      it "without uses" do
        TestClass.virtual_column :vcol1, :type => :string
        expect(TestClass.virtual_includes(:vcol1)).to be_blank
      end

      it "with uses" do
        TestClass.virtual_column :vcol1, :type => :string, :uses => :col1
        expect(TestClass.virtual_includes(:vcol1)).to eq(:col1)
      end

      it "with arel" do
        TestClass.virtual_column :vcol1, :type => :boolean, :arel => ->(t) { t.grouping(t[:vcol].lower) }
        expect(TestClass.arel_attribute("vcol1").to_sql).to match(/LOWER\(["`]test_classes["`].["`]vcol["`]\)/)
      end

      it "can have multiple virtual columns defined by string or symbol" do
        TestClass.virtual_column :existing_vcol, :type => :string
        TestClass.virtual_column :vcol1, :type => :string
        TestClass.virtual_column "vcol2", :type => :string

        expect(TestClass.virtual_attribute_names).to match_array(%w[existing_vcol vcol1 vcol2])
      end
    end

    context ".virtual_attribute_names" do
      it "has virtual attributes (string or symbol)" do
        TestClass.virtual_column :existing_vcol, :type => :string
        TestClass.virtual_column :vcol1, :type => :string
        TestClass.virtual_column "vcol2", :type => :string

        expect(TestClass.virtual_attribute_names).to match_array(%w[existing_vcol vcol1 vcol2])
      end

      it "does not have aliases" do
        TestClass.virtual_attribute :existing_vcol, :string
        TestClass.alias_attribute :col2, :col1

        expect(TestClass.virtual_attribute_names).not_to include("col2")
      end

      it "supports virtual_column aliases" do
        TestClass.virtual_attribute :existing_vcol, :string
        TestClass.alias_attribute :col3, :col1
        TestClass.virtual_attribute :col3, :integer

        expect(TestClass.virtual_attribute_names).to include("col3")
      end
    end

    shared_examples_for "TestClass with virtual columns" do
      context "TestClass" do
        it ".virtual_attribute_names" do
          expect(TestClass.virtual_attribute_names).to match_array(@vcols_strs)
        end

        it ".attribute_names" do
          expect(TestClass.attribute_names).to match_array(@cols_strs)
        end

        context ".virtual_attribute?" do
          context "with virtual column" do
            it("as string") { expect(TestClass.virtual_attribute?("vcol1")).to be_truthy }
            it("as symbol") { expect(TestClass.virtual_attribute?(:vcol1)).to  be_truthy }
          end

          context "with column" do
            it("as string") { expect(TestClass.virtual_attribute?("col1")).not_to be_truthy }
            it("as symbol") { expect(TestClass.virtual_attribute?(:col1)).not_to  be_truthy }
          end

          context "with alias" do
            before { TestClass.alias_attribute :col2, :col1 }
            it("as string") { expect(TestClass.virtual_attribute?("col1")).not_to be_truthy }
            it("as symbol") { expect(TestClass.virtual_attribute?(:col1)).not_to  be_truthy }
          end
        end

        it ".replace_virtual_fields" do
          expect(TestClass.replace_virtual_fields(:vcol1)).to be_nil
          expect(TestClass.replace_virtual_fields(:ref1)).to eq(:ref1)
          expect(TestClass.replace_virtual_fields([:vcol1])).to eq([])
          expect(TestClass.replace_virtual_fields([:vcol1, :ref1])).to eq([:ref1])
          expect(TestClass.replace_virtual_fields(:vcol1 => {})).to eq({})
          expect(TestClass.replace_virtual_fields(:vcol1 => {}, :ref1 => {})).to eq(:ref1 => {})
        end
      end
    end

    shared_examples_for "TestSubclass with virtual columns" do
      context "TestSubclass" do
        it ".virtual_attribute_names" do
          expect(test_sub_class.virtual_attribute_names).to match_array(@vcols_sub_strs)
        end

        it ".attribute_names" do
          expect(test_sub_class.attribute_names).to match_array(@cols_sub_strs)
        end

        context ".virtual_attribute?" do
          context "with virtual column" do
            it("as string") { expect(test_sub_class.virtual_attribute?("vcolsub1")).to be_truthy }
            it("as symbol") { expect(test_sub_class.virtual_attribute?(:vcolsub1)).to  be_truthy }
          end

          context "with column" do
            it("as string") { expect(test_sub_class.virtual_attribute?("col1")).not_to be_truthy }
            it("as symbol") { expect(test_sub_class.virtual_attribute?(:col1)).not_to  be_truthy }
          end
        end

        it ".replace_virtual_fields" do
          expect(test_sub_class.replace_virtual_fields(:vcol1)).to             be_nil
          expect(test_sub_class.replace_virtual_fields(:vcolsub1)).to          be_nil
          expect(test_sub_class.replace_virtual_fields(:ref1)).to eq(:ref1)
          expect(test_sub_class.replace_virtual_fields([:vcol1])).to eq([])
          expect(test_sub_class.replace_virtual_fields([:vcolsub1])).to eq([])
          expect(test_sub_class.replace_virtual_fields([:vcolsub1, :vcol1, :ref1])).to eq([:ref1])
          expect(test_sub_class.replace_virtual_fields(:vcol1    => {})).to eq({})
          expect(test_sub_class.replace_virtual_fields(:vcolsub1 => {})).to eq({})
          expect(test_sub_class.replace_virtual_fields(:vcolsub1 => {}, :vcol1 => {}, :ref1 => {})).to eq(:ref1 => {})
        end
      end
    end

    context "with virtual columns" do
      before do
        TestClass.virtual_column :vcol1, :type => :string
        TestClass.virtual_column :vcol2, :type => :string

        @vcols_strs = ["vcol1", "vcol2"]
        @vcols_syms = [:vcol1, :vcol2]
        @cols_strs  = @vcols_strs + ["id", "col1", "str"]
        @cols_syms  = @vcols_syms + [:id, :col1]
      end

      it_should_behave_like "TestClass with virtual columns"

      context "and TestSubclass with virtual columns" do
        let(:test_sub_class) do
          Class.new(TestClass) do
            virtual_column :vcolsub1, :type => :string
          end
        end
        before do
          test_sub_class
          @vcols_sub_strs = @vcols_strs + ["vcolsub1"]
          @vcols_sub_syms = @vcols_syms + [:vcolsub1]
          @cols_sub_strs  = @vcols_sub_strs + ["id", "col1", "str"]
          @cols_sub_syms  = @vcols_sub_syms + [:id, :col1]
        end

        it_should_behave_like "TestClass with virtual columns" # Shows inheritance doesn't pollute base class
        it_should_behave_like "TestSubclass with virtual columns"
      end
    end

    it "should not have any virtual reflections" do
      expect(TestClass.virtual_reflections).to be_empty
      expect(TestClass.reflections_with_virtual.stringify_keys).to eq(TestClass.reflections)
      expect(TestClass.reflections_with_virtual).to eq(TestClass.reflections.symbolize_keys)
    end

    context "add_virtual_reflection integration" do
      it "with invalid parameters" do
        expect { TestClass.virtual_has_one }.to raise_error(ArgumentError)
      end

      it "with symbol name" do
        TestClass.virtual_has_one :vref1
        expect(TestClass.virtual_reflection?(:vref1)).to be_truthy
        expect(TestClass.virtual_reflection(:vref1).name).to eq(:vref1)
      end

      it("with has_one macro") do
        TestClass.virtual_has_one(:vref1)
        expect(TestClass.virtual_reflection(:vref1).macro).to eq(:has_one)
      end

      it("with has_many macro") do
        TestClass.virtual_has_many(:vref1)
        expect(TestClass.virtual_reflection(:vref1).macro).to eq(:has_many)
      end

      it("with belongs_to macro") do
        TestClass.virtual_belongs_to(:vref1)
        expect(TestClass.virtual_reflection(:vref1).macro).to eq(:belongs_to)
      end

      it "without uses" do
        TestClass.virtual_has_one :vref1
        expect(TestClass.virtual_includes(:vref1)).to be_nil
      end

      it "with uses" do
        TestClass.virtual_has_one :vref1, :uses => :ref1
        expect(TestClass.virtual_includes(:vref1)).to eq(:ref1)
      end
    end

    describe "#virtual_has_many" do
      it "use collect for virtual_ids column" do
        c = Class.new(TestClassBase) do
          self.table_name = 'test_classes'
          virtual_has_many(:hosts)
          def hosts
            [OpenStruct.new(:id => 5), OpenStruct.new(:id => 6)]
          end
        end.new

        expect(c.host_ids).to eq([5, 6])
      end

      it "use Relation#ids for virtual_ids column" do
        c = Class.new(TestClassBase) do
          self.table_name = 'test_classes'
          virtual_has_many(:hosts)
          def hosts
            OpenStruct.new(:ids => [5, 6])
          end
        end.new

        expect(c.host_ids).to eq([5, 6])
      end
    end

    %w[has_one has_many belongs_to].each do |macro|
      virtual_method = "virtual_#{macro}"

      context ".#{virtual_method}" do
        it "with symbol name" do
          TestClass.send(virtual_method, :vref1)
          expect(TestClass.virtual_reflection?(:vref1)).to be_truthy
          expect(TestClass.virtual_reflection(:vref1).name).to eq(:vref1)
        end

        it "without uses" do
          TestClass.send(virtual_method, :vref1)
          expect(TestClass.virtual_includes(:vref1)).to be_nil
        end

        it "with uses" do
          TestClass.send(virtual_method, :vref1, :uses => :ref1)
          expect(TestClass.virtual_includes(:vref1)).to eq(:ref1)
        end
      end
    end

    context "virtual_reflection assignment" do
      it "" do
        TestClass.virtual_has_one :vref1
        TestClass.virtual_has_many :vref2

        expect(TestClass.virtual_reflections.length).to eq(2)
        expect(TestClass.virtual_reflections.keys).to match_array([:vref1, :vref2])
      end

      it "with existing virtual reflections" do
        TestClass.virtual_has_one :existing_vref

        TestClass.virtual_has_one :vref1
        TestClass.virtual_has_many :vref2

        expect(TestClass.virtual_reflections.length).to eq(3)
        expect(TestClass.virtual_reflections.keys).to match_array([:existing_vref, :vref1, :vref2])
      end
    end

    shared_examples_for "TestClass with virtual reflections" do
      context "TestClass" do
        it ".virtual_reflections" do
          expect(TestClass.virtual_reflections.keys).to match_array(@vrefs_syms)
          expect(TestClass.virtual_reflections.values.collect(&:name)).to match_array(@vrefs_syms)
        end

        it ".reflections_with_virtual" do
          expect(TestClass.reflections_with_virtual.keys).to match_array(@refs_syms)
          expect(TestClass.reflections_with_virtual.values.collect(&:name)).to match_array(@refs_syms)
        end

        context ".virtual_reflection?" do
          context "with virtual reflection" do
            it("as string") { expect(TestClass.virtual_reflection?("vref1")).to be_truthy }
            it("as symbol") { expect(TestClass.virtual_reflection?(:vref1)).to  be_truthy }
          end

          context "with reflection" do
            it("as string") { expect(TestClass.virtual_reflection?("ref1")).not_to be_truthy }
            it("as symbol") { expect(TestClass.virtual_reflection?(:ref1)).not_to  be_truthy }
          end
        end

        it ".replace_virtual_fields" do
          expect(TestClass.replace_virtual_fields(:vref1)).to be_nil
          expect(TestClass.replace_virtual_fields(:ref1)).to eq(:ref1)
          expect(TestClass.replace_virtual_fields([:vref1])).to eq([])
          expect(TestClass.replace_virtual_fields([:vref1, :ref1])).to eq([:ref1])
          expect(TestClass.replace_virtual_fields(:vref1 => {})).to eq({})
          expect(TestClass.replace_virtual_fields(:vref1 => {}, :ref1 => {})).to eq(:ref1 => {})
        end
      end
    end

    shared_examples_for "TestSubclass with virtual reflections" do
      context "TestSubclass" do
        it ".virtual_reflections" do
          expect(test_sub_class.virtual_reflections.keys).to match_array(@vrefs_sub_syms)
          expect(test_sub_class.virtual_reflections.values.collect(&:name)).to match_array(@vrefs_sub_syms)
        end

        it ".reflections_with_virtual" do
          expect(test_sub_class.reflections_with_virtual.keys).to match_array(@refs_sub_syms)
          expect(test_sub_class.reflections_with_virtual.values.collect(&:name)).to match_array(@refs_sub_syms)
        end

        context ".virtual_reflection?" do
          context "with virtual reflection" do
            it("as string") { expect(TestClass.virtual_reflection?("vref1")).to be_truthy }
            it("as symbol") { expect(TestClass.virtual_reflection?(:vref1)).to  be_truthy }
          end

          context "with reflection" do
            it("as string") { expect(TestClass.virtual_reflection?("ref1")).not_to be_truthy }
            it("as symbol") { expect(TestClass.virtual_reflection?(:ref1)).not_to  be_truthy }
          end
        end

        it ".replace_virtual_fields" do
          expect(test_sub_class.replace_virtual_fields(:vref1)).to be_nil
          expect(test_sub_class.replace_virtual_fields(:vrefsub1)).to be_nil
          expect(test_sub_class.replace_virtual_fields(:ref1)).to eq(:ref1)
          expect(test_sub_class.replace_virtual_fields([:vref1])).to eq([])
          expect(test_sub_class.replace_virtual_fields([:vrefsub1])).to eq([])
          expect(test_sub_class.replace_virtual_fields([:vrefsub1, :vref1, :ref1])).to eq([:ref1])
          expect(test_sub_class.replace_virtual_fields(:vref1 => {})).to eq({})
          expect(test_sub_class.replace_virtual_fields(:vrefsub1 => {})).to eq({})
          expect(test_sub_class.replace_virtual_fields(:vrefsub1 => {}, :vref1 => {}, :ref1 => {})).to eq(:ref1 => {})
        end
      end
    end

    context "with virtual reflections" do
      before do
        TestClass.virtual_has_one :vref1
        TestClass.virtual_has_one :vref2

        @vrefs_syms = [:vref1, :vref2]
        @refs_syms  = @vrefs_syms + [:ref1]
      end

      it_should_behave_like "TestClass with virtual reflections"

      context "and TestSubclass with virtual reflections" do
        let(:test_sub_class) do
          Class.new(TestClass) do
            def self.reflections
              super.merge(:ref2 => OpenStruct.new(:name => :ref2, :options => {}, :klass => TestClass))
            end

            virtual_has_one :vrefsub1
          end
        end
        before do
          test_sub_class
          @vrefs_sub_syms = @vrefs_syms + [:vrefsub1]
          @refs_sub_syms  = @vrefs_sub_syms + [:ref1, :ref2]
        end

        it_should_behave_like "TestClass with virtual reflections" # Shows inheritance doesn't pollute base class
        it_should_behave_like "TestSubclass with virtual reflections"
      end
    end

    context "with both virtual columns and reflections" do
      before do
        TestClass.virtual_column  :vcol1, :type => :string
        TestClass.virtual_has_one :vref1
      end

      context ".virtual_field?" do
        context "with virtual reflection" do
          it("as string") { expect(TestClass.virtual_reflection?("vref1")).to be_truthy }
          it("as symbol") { expect(TestClass.virtual_reflection?(:vref1)).to  be_truthy }
        end

        context "with reflection" do
          it("as string") { expect(TestClass.virtual_reflection?("ref1")).not_to be_truthy }
          it("as symbol") { expect(TestClass.virtual_reflection?(:ref1)).not_to  be_truthy }
        end

        context "with virtual column" do
          it("as string") { expect(TestClass.virtual_attribute?("vcol1")).to be_truthy }
          it("as symbol") { expect(TestClass.virtual_attribute?(:vcol1)).to  be_truthy }
        end

        context "with column" do
          it("as string") { expect(TestClass.virtual_attribute?("col1")).not_to be_truthy }
          it("as symbol") { expect(TestClass.virtual_attribute?(:col1)).not_to  be_truthy }
        end
      end
    end

    describe ".attribute_supported_by_sql?" do
      it "supports real columns" do
        expect(TestClass.attribute_supported_by_sql?(:col1)).to be_truthy
      end

      it "supports aliases" do
        TestClass.alias_attribute :col2, :col1

        expect(TestClass.attribute_supported_by_sql?(:col2)).to be_truthy
      end

      it "does not support virtual columns" do
        class TestClass
          virtual_attribute :col2, :integer
          def col2
            col1
          end
        end
        expect(TestClass.attribute_supported_by_sql?(:col2)).to be_falsey
      end

      it "supports virtual columns with arel" do
        class TestClass
          virtual_attribute :col2, :integer, :arel => ->(t) { t.grouping(t.class.arel_attribute(:col1)) }
          def col2
            col1
          end
        end
        expect(TestClass.attribute_supported_by_sql?(:col2)).to be_truthy
      end

      it "supports delegates" do
        TestClass.virtual_delegate :col1, :prefix => 'parent', :to => :ref1

        expect(TestClass.attribute_supported_by_sql?(:parent_col1)).to be_truthy
      end

      it "does not support bogus columns" do
        expect(TestClass.attribute_supported_by_sql?(:bogus_junk)).to be_falsey
      end

      # it "supports on an aaar class" do
      #   c = Class.new(ActsAsArModel)

      #   expect(c.attribute_supported_by_sql?(:col)).to eq(false)
      # end
    end

    describe ".attribute_supported_by_sql?" do
      it "supports real columns" do
        expect(TestClass.attribute_supported_by_sql?(:col1)).to be_truthy
      end

      it "supports aliases" do
        TestClass.alias_attribute :col2, :col1

        expect(TestClass.attribute_supported_by_sql?(:col2)).to be_truthy
      end

      it "does not support virtual columns" do
        class TestClass
          virtual_attribute :col2, :integer
          def col2
            col1
          end
        end
        expect(TestClass.attribute_supported_by_sql?(:col2)).to be_falsey
      end

      it "supports virtual columns with arel" do
        class TestClass
          virtual_attribute :col2, :integer, :arel => ->(t) { t.grouping(t.class.arel_attribute(:col1)) }
          def col2
            col1
          end
        end
        expect(TestClass.attribute_supported_by_sql?(:col2)).to be_truthy
      end

      it "supports delegates" do
        TestClass.virtual_delegate :col1, :prefix => 'parent', :to => :ref1

        expect(TestClass.attribute_supported_by_sql?(:parent_col1)).to be_truthy
      end
    end

    describe ".arel_attribute" do
      it "supports aliases" do
        TestClass.alias_attribute :col2, :col1

        arel_attr = TestClass.arel_attribute(:col2)
        expect(arel_attr).to_not be_nil
        expect(arel_attr.name).to eq("col1") # typically this is a symbol. not perfect but it works
      end

      # NOTE: should not need to add a virtual attribute to an alias
      # TODO: change code for reports and automate to expose aliases like it does with attributes/virtual attributes.
      it "supports aliases marked as a virtual_attribute" do
        TestClass.alias_attribute :col2, :col1
        TestClass.virtual_attribute :col2, :integer

        arel_attr = TestClass.arel_attribute(:col2)
        expect(arel_attr).to_not be_nil
        expect(arel_attr.name).to eq("col1") # typically this is a symbol. not perfect but it works
      end
    end

    describe "#select" do
      it "supports virtual attributes" do
        class TestClass
          virtual_attribute :col2, :integer, :arel => ->(t) { t.grouping(arel_attribute(:col1)) }
          def col2
            if has_attribute?("col2")
              col2
            else
              # typically we'd return col1
              # but we're testing that virtual columns are working
              # col1
              raise "NOPE"
            end
          end
        end

        TestClass.create(:col1 => 20)
        expect(TestClass.select(:col2).first[:col2]).to eq(20)
      end

      before do
        # OperatingSystem (child)
        class TestOtherClass < ActiveRecord::Base
          def self.connection
            TestClassBase.connection
          end
          belongs_to :parent, :class_name => 'TestClass', :foreign_key => :ocol1

          include VirtualFields
        end
        TestClass.has_many :children, :class_name => 'TestOtherClass', :foreign_key => :ocol1
      end

      after do
        Object.send(:remove_const, :TestOtherClass)
      end

      it "supports #includes with #references" do
        klass  = TestClass
        vm     = klass.create
        table  = klass.arel_table
        str_id = Arel::Nodes::NamedFunction.new("CAST", [table[:id].as("CHAR")]).as("str_id")
        result = klass.select(str_id).includes(:children => {}).references(:children)

        expect(result.first.attributes["str_id"]).to eq(vm.id.to_s)
      end

      it "supports #includes with #references and empty resultsets" do
        klass  = TestClass
        table  = klass.arel_table
        str_id = Arel::Nodes::NamedFunction.new("CAST", [table[:id].as("CHAR")]).as("str_id")
        result = klass.select(str_id).includes(:children => {}).references(:children)

        expect(result.first).to be_blank
      end
    end

    describe ".virtual_delegate" do
      # double purposing col1. It has an actual value in the child class
      let(:parent) { TestClass.create(:col1 => 4) }

      it "delegates to child" do
        TestClass.virtual_delegate :col1, :prefix => 'parent', :to => :ref1
        tc = TestClass.new(:ref1 => parent)
        expect(tc.parent_col1).to eq(4)
      end

      it "delegates to nil child" do
        TestClass.virtual_delegate :col1, :prefix => 'parent', :to => :ref1, :allow_nil => true
        tc = TestClass.new
        expect(tc.parent_col1).to be_nil
      end

      it "defines virtual attribute" do
        TestClass.virtual_delegate :col1, :prefix => 'parent', :to => :ref1
        expect(TestClass.virtual_attribute_names).to include("parent_col1")
      end

      it "defines with a new name" do
        TestClass.virtual_delegate 'funky_name', :to => "ref1.col1"
        tc = TestClass.new(:ref1 => parent)
        expect(tc.funky_name).to eq(4)
      end

      it "defaults for to nil child (array)" do
        TestClass.virtual_delegate :col1, :prefix => 'parent', :to => :ref1, :allow_nil => true, :default => []
        tc = TestClass.new
        expect(tc.parent_col1).to eq([])
      end

      it "defaults for to nil child (integer)" do
        TestClass.virtual_delegate :col1, :prefix => 'parent', :to => :ref1, :allow_nil => true, :default => 0
        tc = TestClass.new
        expect(tc.parent_col1).to eq(0)
      end

      it "defaults for to nil child (string)" do
        TestClass.virtual_delegate :col1, :prefix => 'parent', :to => :ref1, :allow_nil => true, :default => "def"
        tc = TestClass.new
        expect(tc.parent_col1).to eq("def")
      end
    end

    describe "#sum" do
      it "supports virtual attributes" do
        class TestClass
          virtual_attribute :col2, :integer, :arel => ->(t) { t.grouping(arel_attribute(:col1)) }
          def col2
            col1
          end
        end

        TestClass.create(:col1 => nil)
        TestClass.create(:col1 => 20)
        TestClass.create(:col1 => 30)

        expect(TestClass.sum(:col2)).to eq(50)
      end
    end
  end

  describe "#follow_associations" do
    it "returns base class" do
      expect(Author.follow_associations([])).to eq(Author)
    end

    # Author.has_many :books
    # Book.has_many :bookmarks
    it "follows reflections" do
      expect(Author.follow_associations(%w[books bookmarks])).to eq(Bookmark)
    end

    # Book.belongs_to :author
    # Author.virtual_has_many :named_books
    it "stops at virtual reflections" do
      expect(Book.follow_associations(%w[author named_books])).to be_nil
    end
  end

  describe "#follow_associations_with_virtual" do
    it "returns base class" do
      expect(Author.follow_associations_with_virtual([])).to eq(Author)
    end

    # Author.has_many :books
    # Book.has_many :bookmarks
    it "follows reflections" do
      expect(Author.follow_associations_with_virtual(%w[books bookmarks])).to eq(Bookmark)
    end

    # Book.belongs_to :author
    # Author.virtual_has_many :named_books, :class_name => Book
    it "follows virtual reflections" do
      expect(Book.follow_associations_with_virtual(%w[author named_books])).to eq(Book)
    end
  end

  describe "collect_reflections" do
    it "returns base class" do
      expect(Author.collect_reflections([])).to eq([])
    end

    # Author.has_many :books
    # Book.has_many :bookmarks
    it "follows reflections" do
      expect(Author.collect_reflections(%w[books bookmarks])).to eq(
        [Author.reflect_on_association(:books), Book.reflect_on_association(:bookmarks)]
      )
    end

    # Book.belongs_to :author
    # Author.virtual_has_many :named_books
    it "stops at virtual reflections" do
      expect(Book.collect_reflections(%w[author named_books])).to eq(
        [Book.reflect_on_association(:author)]
      )
    end
  end

  describe "collect_reflections_with_virtual" do
    it "returns base class" do
      expect(Book.collect_reflections_with_virtual([])).to eq([])
    end

    # Author.has_many :books
    # Book.has_many :bookmarks
    it "follows reflections" do
      expect(Author.collect_reflections_with_virtual(%w[books bookmarks])).to eq(
        [Author.reflect_on_association(:books), Book.reflect_on_association(:bookmarks)]
      )
    end

    # Book.belongs_to :author
    # Author.virtual_has_many :named_books
    it "follows virtual reflections" do
      expect(Book.collect_reflections_with_virtual(%w[author named_books])).to eq(
        [Book.reflect_on_association(:author), Author.reflection_with_virtual(:named_books)]
      )
    end
  end

  it "supports non valid sql column names", :with_test_class do
    TestClass.create(:str => "ABC")
    TestClass.virtual_attribute :"lower column", :string, :arel => ->(t) { t.grouping(t[:str].lower) }
    class TestClass
      define_method("lower column") { has_attribute?(:"lower column") ? self[:"lower column"] : str.downcase }
    end

    # testing the select, order, and where clauses
    tc = TestClass.select("lower column").order(:"lower column").find_by(:"lower column" => "abc")
    expect(tc.send("lower column")).to eq("abc")
  end

  context "arel", "aliases" do
    it "supports aliases in select with virtual attribute arel", :with_test_class do
      class TestClass
        virtual_attribute :lc, :string, :arel => ->(t) { t.grouping(t[:str].lower) }

        def lc
          has_attribute?(:downcased) ? self[:downcased] : str.downcase
        end
      end

      obj = TestClass.create(:str => "ABC")

      tc = TestClass.select(TestClass.arel_attribute(:lc).as("downcased")).find_by(:id => obj.id)
      expect(tc[:downcased]).to eq("abc")
    end

    # grouping is the most common way to define arel
    it "supports string literal arel", :with_test_class do
      class TestClass
        virtual_attribute :lc, :string, :arel => ->(t) { t.grouping(Arel.sql("(#{t[:str].lower.to_sql})")) }
        def lc
          has_attribute?(:lc) ? self[:lc] : str.downcase
        end
      end

      obj = TestClass.create(:str => "ABC")

      tc = TestClass.select(:lc).find_by(:id => obj.id)
      expect(tc.lc).to eq("abc")
    end
  end

  describe ".select" do
    it "supports virtual attributes" do
      Author.select(:id, :nick_or_name).first
    end
  end

  describe ".where" do
    it "supports virtual attributes hash syntax" do
      Author.where(:nick_or_name => "abc").first # fails
    end

    it "supports virtual attributes arel syntax" do
      Author.where(Author.arel_attribute(:total_books).gt(5)).first
    end
  end

  describe ".order" do
    it "supports virtual attributes symbol" do
      Author.order(:nick_or_name).first # fails
    end

    it "supports virtual attributes hash" do
      Author.order(:nick_or_name => "ASC").first # fails
    end

    it "supports virtual attributes arel" do
      Author.order(Author.arel_attribute(:nick_or_name)).first
    end
  end

  it "doesn't botch up the attributes", :with_test_class do
    tc = TestClass.select(:id, :str).find(TestClass.create(:str => "abc", :col1 => 55).id)
    expect(tc.attributes.size).to eq(2)
    tc.save
    expect(tc.attributes.size).to eq(2)
  end

  it "doesn't botch up the attributes with includes.references", :with_test_class do
    TestClass.virtual_attribute :vattr, :string
    TestClass.create(:str => "abc", :col1 => 55)

    tc = TestClass.includes(:vattr).references(:vattr).first

    expect(tc.attributes.keys).to match_array(%w[id str col1])
  end
end
