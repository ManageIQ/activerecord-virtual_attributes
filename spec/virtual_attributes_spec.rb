describe ActiveRecord::VirtualAttributes::VirtualFields do
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
        TestClass.virtual_column :vcol1, :type => :boolean, :arel => -> (t) { t[:vcol].lower }
        expect(TestClass.arel_attribute("vcol1").to_sql).to match(/LOWER\(["`]test_classes["`].["`]vcol["`]\)/)
      end

      it "can have multiple virtual columns defined by string or symbol" do
        TestClass.virtual_column :existing_vcol, :type => :string
        TestClass.virtual_column :vcol1, :type => :string
        TestClass.virtual_column "vcol2", :type => :string

        expect(TestClass.virtual_attribute_names).to match_array(%w(existing_vcol vcol1 vcol2))
      end
    end

    context ".virtual_attribute_names" do
      it "has virtual attributes (string or symbol)" do
        TestClass.virtual_column :existing_vcol, :type => :string
        TestClass.virtual_column :vcol1, :type => :string
        TestClass.virtual_column "vcol2", :type => :string

        expect(TestClass.virtual_attribute_names).to match_array(%w(existing_vcol vcol1 vcol2))
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

        it ".remove_virtual_fields" do
          expect(TestClass.remove_virtual_fields(:vcol1)).to          be_nil
          expect(TestClass.remove_virtual_fields(:ref1)).to eq(:ref1)
          expect(TestClass.remove_virtual_fields([:vcol1])).to eq([])
          expect(TestClass.remove_virtual_fields([:vcol1, :ref1])).to eq([:ref1])
          expect(TestClass.remove_virtual_fields(:vcol1 => {})).to eq({})
          expect(TestClass.remove_virtual_fields(:vcol1 => {}, :ref1 => {})).to eq({:ref1 => {}})
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

        it ".remove_virtual_fields" do
          expect(test_sub_class.remove_virtual_fields(:vcol1)).to             be_nil
          expect(test_sub_class.remove_virtual_fields(:vcolsub1)).to          be_nil
          expect(test_sub_class.remove_virtual_fields(:ref1)).to eq(:ref1)
          expect(test_sub_class.remove_virtual_fields([:vcol1])).to eq([])
          expect(test_sub_class.remove_virtual_fields([:vcolsub1])).to eq([])
          expect(test_sub_class.remove_virtual_fields([:vcolsub1, :vcol1, :ref1])).to eq([:ref1])
          expect(test_sub_class.remove_virtual_fields({:vcol1    => {}})).to eq({})
          expect(test_sub_class.remove_virtual_fields({:vcolsub1 => {}})).to eq({})
          expect(test_sub_class.remove_virtual_fields(:vcolsub1 => {}, :volsub1 => {}, :ref1 => {})).to eq({:ref1 => {}})
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
      expect(TestClass.virtual_reflections).to      be_empty
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

      it("with has_one macro")    do
        TestClass.virtual_has_one(:vref1)
        expect(TestClass.virtual_reflection(:vref1).macro).to eq(:has_one)
      end

      it("with has_many macro")   do
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

    %w(has_one has_many belongs_to).each do |macro|
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

        it ".remove_virtual_fields" do
          expect(TestClass.remove_virtual_fields(:vref1)).to          be_nil
          expect(TestClass.remove_virtual_fields(:ref1)).to eq(:ref1)
          expect(TestClass.remove_virtual_fields([:vref1])).to eq([])
          expect(TestClass.remove_virtual_fields([:vref1, :ref1])).to eq([:ref1])
          expect(TestClass.remove_virtual_fields(:vref1 => {})).to eq({})
          expect(TestClass.remove_virtual_fields(:vref1 => {}, :ref1 => {})).to eq({:ref1 => {}})
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

        it ".remove_virtual_fields" do
          expect(test_sub_class.remove_virtual_fields(:vref1)).to             be_nil
          expect(test_sub_class.remove_virtual_fields(:vrefsub1)).to          be_nil
          expect(test_sub_class.remove_virtual_fields(:ref1)).to eq(:ref1)
          expect(test_sub_class.remove_virtual_fields([:vref1])).to eq([])
          expect(test_sub_class.remove_virtual_fields([:vrefsub1])).to eq([])
          expect(test_sub_class.remove_virtual_fields([:vrefsub1, :vref1, :ref1])).to eq([:ref1])
          expect(test_sub_class.remove_virtual_fields({:vref1    => {}})).to eq({})
          expect(test_sub_class.remove_virtual_fields({:vrefsub1 => {}})).to eq({})
          expect(test_sub_class.remove_virtual_fields(:vrefsub1 => {}, :vref1 => {}, :ref1 => {})).to eq({:ref1 => {}})
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
            def self.reflections; super.merge(:ref2 => OpenStruct.new(:name => :ref2, :options => {}, :klass => TestClass)); end

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
          virtual_attribute :col2, :integer, :arel => (-> (t) { t.grouping(t.class.arel_attribute(:col1)) })
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

    describe ".virtual_delegate" do
      # double purposing col1. It has an actual value in the child class
      let(:parent) { TestClass.create(:col1 => 4) }

      it "delegates to parent" do
        TestClass.virtual_delegate :col1, :prefix => 'parent', :to => :ref1
        tc = TestClass.new(:ref1 => parent)
        expect(tc.parent_col1).to eq(4)
      end

      it "delegates to nil parent" do
        TestClass.virtual_delegate :col1, :prefix => 'parent', :to => :ref1, :allow_nil => true
        tc = TestClass.new
        expect(tc.parent_col1).to be_nil
      end

      it "defines parent virtual attribute" do
        TestClass.virtual_delegate :col1, :prefix => 'parent', :to => :ref1
        expect(TestClass.virtual_attribute_names).to include("parent_col1")
      end

      it "delegates to parent (sql)" do
        TestClass.virtual_delegate :col1, :prefix => 'parent', :to => :ref1
        TestClass.create(:ref1 => parent)
        tcs = TestClass.all.select(:id, :col1, TestClass.arel_attribute(:parent_col1).as("x"))
        expect(tcs.map(&:x)).to match_array([nil, 4])
      end

      context "with has_one :parent" do
        before do
          TestClass.has_one :ref2, :class_name => 'TestClass', :foreign_key => :col1, :inverse_of => :ref1
        end
        # child.col1 will be getting parent's (aka tc's) id
        let(:child) { TestClass.create }

        it "delegates to child" do
          TestClass.virtual_delegate :col1, :prefix => 'child', :to => :ref2
          tc = TestClass.create(:ref2 => child)
          expect(tc.child_col1).to eq(tc.id)
        end

        it "delegates to nil child" do
          TestClass.virtual_delegate :col1, :prefix => 'child', :to => :ref2, :allow_nil => true
          tc = TestClass.new
          expect(tc.child_col1).to be_nil
        end

        it "defines child virtual attribute" do
          TestClass.virtual_delegate :col1, :prefix => 'child', :to => :ref2
          expect(TestClass.virtual_attribute_names).to include("child_col1")
        end

        it "delegates to child (sql)" do
          TestClass.virtual_delegate :col1, :prefix => 'child', :to => :ref2
          tc = TestClass.create(:ref2 => child)
          tcs = TestClass.all.select(:id, :col1, :child_col1).to_a
          expect { expect(tcs.map(&:child_col1)).to match_array([nil, tc.id]) }.to match_query_limit_of(0)
        end

        # this may fail in the future as our way of building queries may change
        # just want to make sure it changed due to intentional changes
        it "uses table alias for subquery" do
          TestClass.virtual_delegate :col1, :prefix => 'child', :to => :ref2
          sql = TestClass.all.select(:id, :col1, :child_col1).to_sql
          expect(sql).to match(/["`]test_classes_[^"`]*["`][.]["`]col1["`]/i)
        end
      end

      context "with self join has_one and select" do
        before do
          TestClass.has_one :ref2, -> { select(:col1) }, :class_name => 'TestClass', :foreign_key => :col1
        end
        # child.col1 will be getting parent's (aka tc's) id
        let(:child) { TestClass.create }

        # ensure virtual attribute referencing a relation with a select()
        # does not throw an exception due to multi-column select
        it "properly generates sub select" do
          TestClass.virtual_delegate :col1, :prefix => 'child', :to => :ref2
          TestClass.create(:ref2 => child)
          expect { TestClass.all.select(:id, :child_col1).to_a }.to_not raise_error
        end
      end

      context "with self join has_one and order (self join)" do
        before do
          # TODO: , -> { order(:col1) }
          TestClass.has_one :ref2, :class_name => 'TestClass', :foreign_key => :col1
        end
        # child.col1 will be getting parent's (aka tc's) id
        let(:child) { TestClass.create }

        # ensure virtual attribute referencing a relation with a select()
        # does not throw an exception due to multi-column select
        it "properly generates sub select" do
          TestClass.virtual_delegate :col1, :prefix => 'child', :to => :ref2
          TestClass.create(:ref2 => child)
          expect { TestClass.all.select(:id, :child_col1).to_a }.to_not raise_error
        end
      end

      context "with has_one and order (and many records)" do
        before do
          class TestOtherClass < ActiveRecord::Base # OperatingSystem (child)
            def self.connection
              TestClassBase.connection
            end
            belongs_to :parent, :class_name => 'TestClass', :foreign_key => :ocol1

            include VirtualFields
          end
          # TODO: -> { order(:col1) }
          TestClass.has_one :child, :class_name => 'TestOtherClass', :foreign_key => :ocol1
          TestClass.virtual_delegate :child_str, :to => "child.ostr"
        end

        after do
          Object.send(:remove_const, :TestOtherClass)
        end

        # ensure virtual attribute referencing a relation with has_one and order()
        # works properly
        it "properly generates sub select" do
          parent = TestClass.create(:str => "p")
          child1 = TestOtherClass.create(:parent => parent, :ostr => "c1")
          TestOtherClass.create(:parent => parent, :ostr => "c2")

          expect(TestClass.select(:id, :child_str).find_by(:id => parent.id).child_str).to eq(child1.ostr)
        end
      end

      context "with relation in foreign table" do
        before do
          class TestOtherClass < ActiveRecord::Base
            def self.connection
              TestClassBase.connection
            end
            belongs_to :oref1, :class_name => 'TestClass', :foreign_key => :ocol1

            include VirtualFields
          end
        end

        after do
          Object.send(:remove_const, :TestOtherClass)
        end

        it "delegates to another table" do
          TestOtherClass.virtual_delegate :col1, :to => :oref1
          TestOtherClass.create(:oref1 => TestClass.create)
          TestOtherClass.create(:oref1 => TestClass.create(:col1 => 99))
          tcs = TestOtherClass.all.select(:id, :ocol1, TestOtherClass.arel_attribute(:col1).as("x"))
          expect(tcs.map(&:x)).to match_array([nil, 99])
        end

        # this may fail in the future as our way of building queries may change
        # just want to make sure it changed due to intentional changes
        it "delegates to another table without alias" do
          TestOtherClass.virtual_delegate :col1, :to => :oref1
          sql = TestOtherClass.all.select(:id, :ocol1, TestOtherClass.arel_attribute(:col1).as("x")).to_sql
          expect(sql).to match(/["`]test_classes["`].["`]col1["`]/i)
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
          virtual_attribute :col2, :integer, :arel => (-> (t) { t.grouping(t.class.arel_attribute(:col1)) })
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
          virtual_attribute :col2, :integer, :arel => (-> (t) { t.grouping(arel_attribute(:col1)) })
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

      it "supports virtual attributes with as" do
        class TestClass
          virtual_attribute :col2, :integer, :arel => (-> (t) { t.grouping(arel_attribute(:col1)).as("col2") })
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
        class TestOtherClass < ActiveRecord::Base # OperatingSystem (child)
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
        vm     = TestClass.create
        klass  = vm.class
        table  = klass.arel_table
        str_id = Arel::Nodes::NamedFunction.new("CAST", [table[:id].as("CHAR")]).as("str_id")
        result = klass.select(str_id).includes(:children => {}).references(:children => {})

        expect(result.first.attributes["str_id"]).to eq(vm.id.to_s)
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
          virtual_attribute :col2, :integer, :arel => (-> (t) { t.grouping(arel_attribute(:col1)) })
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
      expect(Author.follow_associations(%w(books bookmarks))).to eq(Bookmark)
    end

    # Book.belongs_to :author
    # Author.virtual_has_many :named_books
    it "stops at virtual reflections" do
      expect(Book.follow_associations(%w(author named_books))).to be_nil
    end
  end

  describe "#follow_associations_with_virtual" do
    it "returns base class" do
      expect(Author.follow_associations_with_virtual([])).to eq(Author)
    end

    # Author.has_many :books
    # Book.has_many :bookmarks
    it "follows reflections" do
      expect(Author.follow_associations_with_virtual(%w(books bookmarks))).to eq(Bookmark)
    end

    # Book.belongs_to :author
    # Author.virtual_has_many :named_books, :class_name => Book
    it "follows virtual reflections" do
      expect(Book.follow_associations_with_virtual(%w(author named_books))).to eq(Book)
    end
  end

  describe "collect_reflections" do
    it "returns base class" do
      expect(Author.collect_reflections([])).to eq([])
    end

    # Author.has_many :books
    # Book.has_many :bookmarks
    it "follows reflections" do
      expect(Author.collect_reflections(%w(books bookmarks))).to eq([
        Author.reflect_on_association(:books), Book.reflect_on_association(:bookmarks)
      ])
    end

    # Book.belongs_to :author
    # Author.virtual_has_many :named_books
    it "stops at virtual reflections" do
      expect(Book.collect_reflections(%w(author named_books))).to eq([
        Book.reflect_on_association(:author)
      ])
    end
  end

  describe "collect_reflections_with_virtual" do
    it "returns base class" do
      expect(Book.collect_reflections_with_virtual([])).to eq([])
    end

    # Author.has_many :books
    # Book.has_many :bookmarks
    it "follows reflections" do
      expect(Author.collect_reflections_with_virtual(%w(books bookmarks))).to eq([
        Author.reflect_on_association(:books), Book.reflect_on_association(:bookmarks)
      ])
    end

    # Book.belongs_to :author
    # Author.virtual_has_many :named_books
    it "follows virtual reflections" do
      expect(Book.collect_reflections_with_virtual(%w(author named_books))).to eq([
        Book.reflect_on_association(:author), Author.reflection_with_virtual(:named_books)
      ])
    end
  end

  context "preloading" do
    before do
      Author.create_with_books(3).books.first.create_bookmarks(2)
    end

    context "virtual column" do
      it "as Symbol" do
        expect { Author.includes(:nick_or_name).load }.to match_query_limit_of(1)
      end

      it "as Array" do
        expect { Author.includes([:nick_or_name]).load }.to match_query_limit_of(1)
        expect { Author.includes([:nick_or_name, :bookmarks]).load }.to match_query_limit_of(3)
      end

      it "as Hash" do
        expect { Author.includes(:nick_or_name => {}).load }.to match_query_limit_of(1)
        expect { Author.includes(:nick_or_name => {}, :bookmarks => :book).load }.to match_query_limit_of(4)
      end
    end

    context "virtual reflection" do
      it "as Symbol" do
        expect { Author.includes(:named_books).load }.to match_query_limit_of(2)
      end

      it "as Array" do
        expect { Author.includes([:named_books]).load }.to match_query_limit_of(2)
        expect { Author.includes([:named_books, :bookmarks]).load }.to match_query_limit_of(3)
      end

      it "as Hash" do
        expect { Author.includes(:named_books => {}).load }.to match_query_limit_of(2)
        expect { Author.includes(:named_books => {}, :bookmarks => :book).load }.to match_query_limit_of(4)
      end
    end

    it "nested virtual fields" do
      expect { Author.includes(:books => :author_name).load }.to match_query_limit_of(3)
    end

    it "virtual field that has nested virtual fields in its :uses clause" do
      expect { Author.includes(:ems_cluster).load }.not_to raise_error
    end

    it "should handle virtual fields in :include when :conditions are also present in calculations" do
      expect { Book.includes([:author_name, :author]).references(:author).where("authors.name = 'test'").count }.to match_query_limit_of(1)
      expect { Book.includes([:author_name, :author]).references(:author).where("authors.id IS NOT NULL").count }.to match_query_limit_of(1)
    end

    it "should fetch virtual fields without includes" do
      book = nil
      expect { book = Book.select(:author_name).first }.to match_query_limit_of(1)
      expect { expect(book.author_name).to eq("foo") }.to match_query_limit_of(0)
    end

    it "should fetch virtual field using includes" do
      book = nil
      expect { book = Book.includes(:author_name).first }.to match_query_limit_of(2)
      expect { expect(book.author_name).to eq("foo") }.to match_query_limit_of(0)
    end

    it "should fetch virtual field using references" do
      skip("AR 5.1 not including properly") if ActiveRecord.version.to_s >= "5.1"
      book = nil
      expect { book = Book.includes(:author_name).references(:author_name).first }.to match_query_limit_of(2)
      expect { expect(book.author_name).to eq("foo") }.to match_query_limit_of(0)
    end

    it "should fetch virtual field using all 3" do
      skip("AR 5.1 not including properly") if ActiveRecord.version.to_s >= "5.1"
      book = nil
      expect { book = Book.select(:author_name).includes(:author_name).references(:author_name).first }.to match_query_limit_of(2)
      expect { expect(book.author_name).to eq("foo") }.to match_query_limit_of(0)
    end

    it "should leverage select for virtual fields" do
      authors = nil
      expect { authors = Author.includes(:books => :author_name).load }.to match_query_limit_of(3)
      expect { expect(authors.first.books.first.author_name).to eq(authors.first.name) }.to match_query_limit_of(0)
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

    expect(tc.attributes.keys).to match_array(%w(id str col1))
  end
end
