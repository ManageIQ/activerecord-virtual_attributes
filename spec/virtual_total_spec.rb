describe VirtualAttributes::VirtualTotal do
  before do
    # rubocop:disable Style/SingleLineMethods, Layout/EmptyLineBetweenDefs, Naming/AccessorMethodName
    class VitualTotalTestBase < ActiveRecord::Base
      self.abstract_class = true

      establish_connection :adapter => 'sqlite3', :database => ':memory:'

      include VirtualFields
    end

    ActiveRecord::Schema.define do
      def self.connection; VitualTotalTestBase.connection; end
      def self.set_pk_sequence!(*); end
      self.verbose = false

      create_table :vt_authors, :force => true, :id => :integer do |t|
        t.string   :name
      end

      create_table :vt_books, :force => true, :id => :integer do |t|
        t.integer  :author_id
        t.string   :name
        t.boolean  :published, :default => false
        t.boolean  :special,   :default => false
        t.integer  :rating
        t.datetime :created_on
      end

      create_table :vt_bookmarks, :force => true, :id => :integer do |t|
        t.integer  :book_id
        t.string   :name
        t.datetime :created_on
      end
    end

    class VtAuthor < VitualTotalTestBase
      def self.connection; VitualTotalTestBase.connection; end

      has_many :books,                             :class_name => "VtBook", :foreign_key => "author_id"
      has_many :ordered_books,   -> { ordered },   :class_name => "VtBook", :foreign_key => "author_id"
      has_many :published_books, -> { published }, :class_name => "VtBook", :foreign_key => "author_id"
      has_many :wip_books,       -> { wip },       :class_name => "VtBook", :foreign_key => "author_id"
      has_many :bookmarks,                         :class_name => "VtBookmark", :through => :books

      virtual_total :total_books, :books
      virtual_total :total_books_published, :published_books
      virtual_total :total_books_in_progress, :wip_books
      # same as total_books, but going through a relation with order
      virtual_total :total_ordered_books, :ordered_books
      # virtual total using through
      virtual_total :total_bookmarks, :bookmarks
      alias v_total_bookmarks total_bookmarks

      # virtual_total using a virtual_has_many
      def named_books
        # I didn't have the creativity needed to find a good ruby only check here
        books.select { |b| b.name }
      end

      virtual_has_many :named_books
      virtual_total :total_named_books, :named_books
      alias v_total_named_books total_named_books

      def self.create_with_books(count = 0)
        create!(:name => "foo").tap { |author| author.create_books(count) }
      end

      def create_books(count, create_attrs = {})
        count.times do
          attrs = {
            :name   => "bar",
            :author => self,
          }.merge(create_attrs)
          VtBook.create(attrs)
        end
      end
    end

    class VtBook < VitualTotalTestBase
      def self.connection; VitualTotalTestBase.connection end

      has_many :bookmarks, :class_name => "VtBookmark", :foreign_key => "book_id"
      belongs_to :author,  :class_name => "VtAuthor",   :foreign_key => "author_id"
      scope :ordered,   -> { order(:created_on => :desc) }
      scope :published, -> { where(:published => true)  }
      scope :wip,       -> { where(:published => false) }

      def self.create_with_bookmarks(count = 0)
        a = VtAuthor.create(:name => "foo")
        create!(:name => "book", :author => a).tap { |book| book.create_bookmarks(count) }
      end

      def create_bookmarks(count, create_attrs = {})
        count.times do
          attrs = {
            :name   => "mark",
            :book   => self,
          }.merge(create_attrs)
          VtBookmark.create(attrs)
        end
      end
    end

    class VtBookmark < VitualTotalTestBase
      def self.connection; VitualTotalTestBase.connection end

      belongs_to :book, :class_name => "VtBook", :foreign_key => "book_id"
    end
    # rubocop:enable Style/SingleLineMethods, Layout/EmptyLineBetweenDefs, Naming/AccessorMethodName
  end

  after do
    VitualTotalTestBase.remove_connection
    Object.send(:remove_const, :VtAuthor)
    Object.send(:remove_const, :VtBook)
    Object.send(:remove_const, :VtBookmark)
    Object.send(:remove_const, :VitualTotalTestBase)
  end

  describe ".virtual_total" do
    context "with a standard has_many" do
      it "sorts by total" do
        author2 = VtAuthor.create_with_books(2)
        author0 = VtAuthor.create_with_books(0)
        author1 = VtAuthor.create_with_books(1)

        expect(VtAuthor.order(:total_books).pluck(:id))
          .to eq([author0, author1, author2].map(&:id))
      end

      it "calculates totals locally" do
        author0_id = VtAuthor.create_with_books(0).id
        author2_id = VtAuthor.create_with_books(2).id
        expect do
          expect(VtAuthor.find(author0_id).total_books).to eq(0)
          expect(VtAuthor.find(author2_id).total_books).to eq(2)
        end.to match_query_limit_of(4)
      end

      it "can bring back totals in primary query" do
        author3 = VtAuthor.create_with_books(3)
        author1 = VtAuthor.create_with_books(1)
        author2 = VtAuthor.create_with_books(2)
        expect do
          author_query = VtAuthor.select(:id, :total_books)
          expect(author_query).to match_array([author3, author1, author2])
          expect(author_query.map(&:total_books)).to match_array([3, 1, 2])
        end.to match_query_limit_of(1)
      end
    end

    context "with a has_many that includes a scope" do
      it "sorts by total" do
        author2 = VtAuthor.create_with_books(2)
        author2.create_books(1, :published => true)
        author0 = VtAuthor.create_with_books(0)
        author0.create_books(2, :published => true)
        author1 = VtAuthor.create_with_books(1)

        expect(VtAuthor.order(:total_books_published).pluck(:id))
          .to eq([author1, author2, author0].map(&:id))
        expect(VtAuthor.order(:total_books_in_progress).pluck(:id))
          .to eq([author0, author1, author2].map(&:id))
      end

      it "calculates totals locally" do
        author0 = VtAuthor.create_with_books(0)
        author0.create_books(2, :published => true)
        author2 = VtAuthor.create_with_books(2)
        author2.create_books(1, :published => true)

        expect do
          expect(VtAuthor.find(author0.id).total_books).to eq(2)
          expect(VtAuthor.find(author0.id).total_books_published).to eq(2)
          expect(VtAuthor.find(author0.id).total_books_in_progress).to eq(0)
          expect(VtAuthor.find(author2.id).total_books).to eq(3)
          expect(VtAuthor.find(author2.id).total_books_published).to eq(1)
          expect(VtAuthor.find(author2.id).total_books_in_progress).to eq(2)
        end.to match_query_limit_of(12)
      end

      it "can bring back totals in primary query" do
        author3 = VtAuthor.create_with_books(3)
        author3.create_books(4, :published => true)
        author1 = VtAuthor.create_with_books(1)
        author1.create_books(5, :published => true)
        author2 = VtAuthor.create_with_books(2)
        author2.create_books(6, :published => true)

        expect do
          cols = %i(id total_books total_books_published total_books_in_progress)
          author_query = VtAuthor.select(*cols).to_a
          expect(author_query).to match_array([author3, author1, author2])
          expect(author_query.map(&:total_books)).to match_array([7, 6, 8])
          expect(author_query.map(&:total_books_published)).to match_array([4, 5, 6])
          expect(author_query.map(&:total_books_in_progress)).to match_array([3, 1, 2])
        end.to match_query_limit_of(1)
      end
    end

    context "with order clauses in the relation" do
      before do
        # Monkey patching VtAuthor for these specs
        class VtAuthor < VitualTotalTestBase
          has_many :recently_published_books, -> { published.order(:created_on => :desc) },
                   :class_name => "VtBook", :foreign_key => "author_id"

          virtual_total :total_recently_published_books, :recently_published_books
          virtual_aggregate :sum_recently_published_books_rating, :recently_published_books, :sum, :rating
        end
      end

      it "sorts by total" do
        author2 = VtAuthor.create_with_books(2)
        author2.create_books(1, :published => true, :rating => 5)
        author0 = VtAuthor.create_with_books(0)
        author0.create_books(2, :published => true, :rating => 2)
        author1 = VtAuthor.create_with_books(1)

        expect(VtAuthor.order(:total_recently_published_books).pluck(:id))
          .to eq([author1, author2, author0].map(&:id))
        expect(VtAuthor.order(:sum_recently_published_books_rating).pluck(:id))
          .to eq([author1, author0, author2].map(&:id))
      end

      it "calculates totals locally" do
        author0 = VtAuthor.create_with_books(0)
        author0.create_books(2, :published => true, :rating => 2)
        author2 = VtAuthor.create_with_books(2)
        author2.create_books(1, :published => true, :rating => 5)

        expect do
          expect(VtAuthor.find(author0.id).total_recently_published_books).to eq(2)
          expect(VtAuthor.find(author0.id).sum_recently_published_books_rating).to eq(4)
          expect(VtAuthor.find(author2.id).total_recently_published_books).to eq(1)
          expect(VtAuthor.find(author2.id).sum_recently_published_books_rating).to eq(5)
        end.to match_query_limit_of(8)
      end

      it "can bring back totals in primary query" do
        author3 = VtAuthor.create_with_books(3)
        author3.create_books(2, :published => true, :rating => 2)
        author1 = VtAuthor.create_with_books(1)
        author1.create_books(3, :published => true, :rating => 1)
        author2 = VtAuthor.create_with_books(2)
        author2.create_books(1, :published => true, :rating => 5)

        expect do
          cols = %i(id total_recently_published_books sum_recently_published_books_rating)
          author_query = VtAuthor.select(*cols).to_a
          expect(author_query).to match_array([author3, author1, author2])
          expect(author_query.map(&:total_recently_published_books)).to match_array([2, 3, 1])
          expect(author_query.map(&:sum_recently_published_books_rating)).to match_array([4, 3, 5])
        end.to match_query_limit_of(1)
      end
    end

    context "with a special books class" do
      before do
        class SpecialVtBook < VtBook
          default_scope { where(:special => true) }

          self.table_name = 'vt_books'
        end

        # Monkey patching VtAuthor for these specs
        class VtAuthor < VitualTotalTestBase
          has_many :special_books,
                   :class_name => "SpecialVtBook", :foreign_key => "author_id"
          has_many :published_special_books, -> { published },
                   :class_name => "SpecialVtBook", :foreign_key => "author_id"

          virtual_total :total_special_books, :special_books
          virtual_total :total_special_books_published, :published_special_books
        end
      end

      after do
        Object.send(:remove_const, :SpecialVtBook)
      end

      context "with a has_many that includes a scope" do
        it "sorts by total" do
          author2 = VtAuthor.create_with_books(2)
          author2.create_books(5, :special => true)
          author2.create_books(1, :special => true, :published => true)
          author0 = VtAuthor.create_with_books(0)
          author0.create_books(2, :special => true)
          author0.create_books(2, :special => true, :published => true)
          author1 = VtAuthor.create_with_books(1)

          expect(VtAuthor.order(:total_special_books).pluck(:id))
            .to eq([author1, author0, author2].map(&:id))
          expect(VtAuthor.order(:total_special_books_published).pluck(:id))
            .to eq([author1, author2, author0].map(&:id))
        end

        it "calculates totals locally" do
          author0 = VtAuthor.create_with_books(0)
          author0.create_books(2, :special => true)
          author0.create_books(2, :special => true, :published => true)
          author2 = VtAuthor.create_with_books(2)
          author2.create_books(5, :special => true)
          author2.create_books(1, :special => true, :published => true)

          expect do
            expect(VtAuthor.find(author0.id).total_books).to eq(4)
            expect(VtAuthor.find(author0.id).total_special_books).to eq(4)
            expect(VtAuthor.find(author0.id).total_special_books_published).to eq(2)
            expect(VtAuthor.find(author2.id).total_books).to eq(8)
            expect(VtAuthor.find(author2.id).total_special_books).to eq(6)
            expect(VtAuthor.find(author2.id).total_special_books_published).to eq(1)
          end.to match_query_limit_of(12)
        end

        it "can bring back totals in primary query" do
          author3 = VtAuthor.create_with_books(3)
          author3.create_books(4, :published => true)
          author1 = VtAuthor.create_with_books(1)
          author1.create_books(2, :special => true)
          author1.create_books(2, :special => true, :published => true)
          author2 = VtAuthor.create_with_books(2)
          author2.create_books(5, :special => true)
          author2.create_books(1, :special => true, :published => true)

          expect do
            cols = %i(
              id
              total_books
              total_books_published
              total_special_books
              total_special_books_published
            )
            author_query = VtAuthor.select(*cols).to_a
            expect(author_query).to match_array([author3, author1, author2])
            expect(author_query.map(&:total_books)).to match_array([7, 5, 8])
            expect(author_query.map(&:total_books_published)).to match_array([4, 2, 1])
            expect(author_query.map(&:total_special_books)).to match_array([0, 4, 6])
            expect(author_query.map(&:total_special_books_published)).to match_array([0, 2, 1])
          end.to match_query_limit_of(1)
        end
      end
    end
  end

  describe ".virtual_total (with real has_many relation ems#total_vms)" do
    let(:base_model) { VtAuthor }
    it "sorts by total" do
      author0 = model_with_children(0)
      author2 = model_with_children(2)
      author1 = model_with_children(1)

      expect(base_model.order(:total_books).pluck(:id))
        .to eq([author0, author1, author2].map(&:id))
    end

    it "calculates totals locally" do
      expect(model_with_children(0).total_books).to eq(0)
      expect(model_with_children(2).total_books).to eq(2)
    end

    it "can bring back totals in primary query" do
      m3 = model_with_children(3)
      m1 = model_with_children(1)
      m2 = model_with_children(2)
      mc = m1.class
      expect {
        ms = mc.select(:id, mc.arel_attribute(:total_books).as("total_books"))
        expect(ms).to match_array([m3, m2, m1])
        expect(ms.map(&:total_books)).to match_array([3, 2, 1])
      }.to match_query_limit_of(1)
    end

    def model_with_children(count)
      VtAuthor.create_with_books(count)
    end
  end

  describe ".virtual_total (with virtual relation (Author#total_named_books)" do
    let(:base_model) { VtAuthor }
    # it can not sort by virtual

    it "calculates totals locally" do
      expect(model_with_children(0).v_total_named_books).to eq(0)
      expect(model_with_children(2).v_total_named_books).to eq(2)
    end

    it "is not defined in sql" do
      expect(base_model.attribute_supported_by_sql?(:total_named_books)).to be(false)
    end

    it "alias is not defined in sql" do
      expect(base_model.attribute_supported_by_sql?(:v_total_named_books)).to be(false)
    end

    def model_with_children(count)
      VtAuthor.create_with_books(count)
    end
  end

  describe ".virtual_total (with through relation (ems#total_storages)" do
    let(:base_model) { VtAuthor }

    it "calculates totals locally" do
      expect(model_with_children(0).total_bookmarks).to eq(0)
      expect(model_with_children(2).total_bookmarks).to eq(4)
    end

    it "is not defined in sql" do
      expect(base_model.attribute_supported_by_sql?(:total_bookmarks)).to be(false)
    end

    def model_with_children(count)
      base_model.create_with_books(count).tap do |author|
        author.books.each do |book|
          book.create_bookmarks(2)
        end
      end.reload
    end
  end

  # Causes an issue on postgres since it doesn't allow you to have an ORDER BY with a column
  # that isn't in the SELECT clause...
  #
  # sqlite works fine
  describe ".virtual_total (with real has_many relation and .order() in scope vm#provisioned_storage)" do
    context "with no hardware" do
      let(:base_model) { VtAuthor }

      it "calculates totals locally" do
        expect(model_with_children(0).total_ordered_books).to eq(0)
        expect(model_with_children(2).total_ordered_books).to eq(2)
      end

      it "uses calculated (inline) attribute" do
        auth1 = model_with_children(0)
        auth2 = model_with_children(2)
        query = base_model.select(:id, :total_ordered_books).load
        expect do
          expect(query).to match_array([auth1, auth2])
          expect(query.map(&:total_ordered_books)).to match_array([0, 2])
        end.to match_query_limit_of(0)
      end

      def model_with_children(count)
        VtAuthor.create_with_books(count).reload
      end
    end
  end
end
