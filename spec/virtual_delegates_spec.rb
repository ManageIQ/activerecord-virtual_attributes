RSpec.describe ActiveRecord::VirtualAttributes::VirtualDelegates, :with_test_class do
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
    tcs = TestClass.all.select(:id, :col1, TestClass.arel_table[:parent_col1].as("x"))
    expect(tcs.map(&:x)).to match_array([nil, 4])
  end

  context "invalid" do
    it "expects a ':to' for delegation" do
      expect do
        TestClass.virtual_delegate :col1
      end.to raise_error(ArgumentError, /needs an association/)
    end

    it "only allows 1 method when delegating to a specific method" do
      expect do
        TestClass.virtual_delegate :col1, :col2, :to => "ref1.method"
      end.to raise_error(ArgumentError, /single virtual method/)
    end

    it "only allows 1 level deep delegation" do
      expect do
        TestClass.virtual_delegate :col1, :to => "ref1.method.method2"
      end.to raise_error(ArgumentError, /single association/)
    end

    it "detects invalid destination" do
      expect do
        TestClass.virtual_delegate :col1, :to => "bogus_ref.method"
        TestClass.new
      end.to raise_error(ArgumentError, /needs an association/)
    end
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
      expect { expect(tcs.map(&:child_col1)).to match_array([nil, tc.id]) }.to_not make_database_queries
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
      # OperatingSystem (child)
      class TestOtherClass < ActiveRecord::Base
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
      tcs = TestOtherClass.all.select(:id, :ocol1, TestOtherClass.arel_table[:col1].as("x"))
      expect(tcs.map(&:x)).to match_array([nil, 99])

      expect { tcs = TestOtherClass.all.select(:id, :ocol1, :col1).load }.to make_database_queries(:count => 1)
      expect(tcs.map(&:col1)).to match_array([nil, 99])
    end

    # this may fail in the future as our way of building queries may change
    # just want to make sure it changed due to intentional changes
    it "delegates to another table without alias" do
      TestOtherClass.virtual_delegate :col1, :to => :oref1
      sql = TestOtherClass.all.select(:id, :ocol1, TestOtherClass.arel_table[:col1].as("x")).to_sql
      expect(sql).to match(/["`]test_classes["`].["`]col1["`]/i)
    end

    it "supports :type (and works when reference IS valid)" do
      TestOtherClass.virtual_delegate :col1, :to => :oref1, :type => :integer
      TestOtherClass.create(:oref1 => TestClass.create)
      TestOtherClass.create(:oref1 => TestClass.create(:col1 => 99))
      tcs = TestOtherClass.all.select(:id, :ocol1, TestOtherClass.arel_table[:col1].as("x"))
      expect(tcs.map(&:x)).to match_array([nil, 99])
    end

    it "detects bad reference" do
      TestOtherClass.virtual_delegate :bogus, :to => :oref1, :type => :integer
      expect { TestOtherClass.new }.not_to raise_error
      expect { TestOtherClass.new(:oref1 => TestClass.new).bogus }.to raise_error(NoMethodError)
    end

    it "detects bad reference in sql" do
      TestOtherClass.virtual_delegate :bogus, :to => :oref1, :type => :integer
      # any exception will do
      expect { TestOtherClass.select(:bogus).first }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "doesn't reference target class when :type is specified" do
      TestOtherClass.has_many :others, :class_name => "InvalidType"
      TestOtherClass.virtual_delegate :col4, :to => :others, :type => :integer

      # doesn't lookup InvalidType class with this model
      expect { TestOtherClass.new }.not_to raise_error
      # referencing the relation still accesses the model (which is invalid so blows up)
      expect { TestOtherClass.new.col4 }.to raise_error(NameError)
    end

    it "catches invalid references" do
      TestOtherClass.virtual_delegate :col4, :to => :others, :type => :integer

      expect { model.new }.to raise_error(NameError)
    end

    it "catches invalid column" do
      TestOtherClass.virtual_delegate :col4, :to => :oref1, :type => :integer

      expect { model.new }.to raise_error(NameError)
    end
  end

  context "with polymorphic has_one" do
    it "supports select" do
      author = Author.create(:name => "no one of consequence")
      author.photos.create(:description => 'good')

      author = Author.select(:id, :current_photo_description).find(author.id)
      expect(author.current_photo_description).to eq("good")
    end

    it "supports bind variables in association" do
      author = Author.create(:name => "no one of consequence")
      author.photos.create(:description => 'good', :purpose => "fancy")

      author = Author.select(:id, :fancy_photo_description).find(author.id)
      expect(author).to preload_values(:fancy_photo_description, "good")
    end

    it "respects type" do
      author = Author.create(:name => "no one of consequence")
      book = author.books.create(:name => "nothing of consequence", :id => author.id)
      book.photos.create(:description => 'bad')

      author = Author.select(:id, :current_photo_description).find(author.id)
      expect(author.current_photo_description).to eq(nil)
    end

    it "handles polymorphic in" do
      author = Author.create(:name => "no one of consequence")
      author.books.create(:name => "nothing of consequence", :id => author.id)
      author.photos.create(:description => 'good')

      actual = Author.where(:current_photo_description => %w[good ok]).find(author.id)
      expect(actual).to eq(author)
    end

    it "handles polymorphic or" do
      author = Author.create(:name => "no one of consequence")
      author.books.create(:name => "nothing of consequence", :id => author.id)
      author.photos.create(:description => 'good')

      # ensuring that the parens for delegates don't mess up sql
      actual = Author.where(:current_photo_description => "good")
                     .or(Author.where(:current_photo_description => "ok"))
                     .first
      expect(actual).to eq(author)
    end
  end
end
