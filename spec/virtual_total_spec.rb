RSpec.describe VirtualAttributes::VirtualTotal do
  before do
    Author.delete_all
    Book.delete_all
    Bookmark.delete_all
  end

  describe ".select" do
    it "supports virtual_totals" do
      Author.select(:id, :total_books).first
    end
  end

  describe ".where" do
    it "supports virtual_totals hash syntax" do
      Author.where(:total_books => 5).first
    end

    it "supports virtual_totals arel syntax" do
      Author.where(Author.arel_table[:total_books].gt(5)).first
    end
  end

  describe ".order" do
    it "supports virtual_totals" do
      Author.order(:total_books).first
    end
  end

  describe "calculate" do
    before do
      Author.create_with_books(2)
      Author.create_with_books(3)
    end

    it "counts records" do
      expect(Author.count).to eq(2)
    end

    it "counts records with includes" do
      expect(Author.includes(:books).count).to eq(2)
    end

    it "calculates aggregate of virtual attribute" do
      expect(Author.sum(:total_books)).to eq(5)
    end

    # # fails
    # it "calculates aggregate of virtual attribute with includes" do
    #   expect(Author.includes(:books).sum(:total_books)).to eq(5)
    # end
  end

  describe ".virtual_total" do
    context "with a standard has_many" do
      it "sorts by total attribute" do
        author2 = Author.create_with_books(2)
        author0 = Author.create
        author1 = Author.create_with_books(1)

        expect(Author.order(:total_books).pluck(:id))
          .to eq([author0, author1, author2].map(&:id))
      end

      it "calculates totals using a query" do
        author0 = Author.create.reload
        author2 = Author.create_with_books(2).reload
        expect do
          expect(author0.total_books).to eq(0)
          expect(author2.total_books).to eq(2)
        end.to make_database_queries(:count => 2)
      end

      it "calculates totals with preloaded association" do
        author_id = Author.create_with_books(2).id
        author = Author.includes(:books).find(author_id)

        expect do
          expect(author.total_books).to eq(2)
        end.to_not make_database_queries
      end

      it "calculates totals with preloaded associations with no associated records" do
        author_id = Author.create.id
        author = Author.includes(:books).find(author_id)

        expect do
          expect(author.total_books).to eq(0)
        end.to_not make_database_queries
      end

      it "calculates totals with attribute" do
        author3 = Author.create_with_books(3)
        author1 = Author.create_with_books(1)
        author2 = Author.create_with_books(2)
        expect do
          author_query = Author.select(:id, :total_books)
          expect(author_query).to match_array([author3, author1, author2])
          expect(author_query.map(&:total_books)).to match_array([3, 1, 2])
        end.to make_database_queries(:count => 1)
      end

      it "with no associated records calculates totals with attribute" do
        Author.create
        query = Author.select(:id, :total_books).load
        expect do
          expect(query.map(&:total_books)).to match_array([0])
        end.to_not make_database_queries
      end
    end

    context "virtual sum of a virtual sum" do
      it "calculates sum of a sum" do
        author2 = Author.create
        author2.create_books(2, :published => true, :rating => 5) # 2*5
        author0 = Author.create
        author0.create_books(3, :published => true, :rating => 2) # 3*2
        author1 = Author.create_with_books(1)
        author1.create_books(1, :published => true, :rating => 0) # 0

        expect(Author.sum(:sum_recently_published_books_rating)).to eq(16)
      end
    end

    context "with a has_many that includes a scope" do
      it "sorts by total" do
        author2 = Author.create_with_books(2)
        author2.create_books(1, :published => true)
        author0 = Author.create
        author0.create_books(2, :published => true)
        author1 = Author.create_with_books(1)

        expect(Author.order(:total_books_published).pluck(:id))
          .to eq([author1, author2, author0].map(&:id))
        expect(Author.order(:total_books_in_progress).pluck(:id))
          .to eq([author0, author1, author2].map(&:id))
      end

      it "calculates totals locally" do
        author0 = Author.create
        author0.create_books(2, :published => true)
        author2 = Author.create_with_books(2)
        author2.create_books(1, :published => true)

        expect do
          expect(Author.find(author0.id).total_books).to eq(2)
          expect(Author.find(author0.id).total_books_published).to eq(2)
          expect(Author.find(author0.id).total_books_in_progress).to eq(0)
          expect(Author.find(author2.id).total_books).to eq(3)
          expect(Author.find(author2.id).total_books_published).to eq(1)
          expect(Author.find(author2.id).total_books_in_progress).to eq(2)
        end.to make_database_queries(:count => 12)
      end

      it "can bring back totals in primary query" do
        author3 = Author.create_with_books(3)
        author3.create_books(4, :published => true)
        author1 = Author.create_with_books(1)
        author1.create_books(5, :published => true)
        author2 = Author.create_with_books(2)
        author2.create_books(6, :published => true)

        expect do
          cols = %i[id total_books total_books_published total_books_in_progress]
          author_query = Author.select(*cols).to_a
          expect(author_query).to match_array([author3, author1, author2])
          expect(author_query.map(&:total_books)).to match_array([7, 6, 8])
          expect(author_query.map(&:total_books_published)).to match_array([4, 5, 6])
          expect(author_query.map(&:total_books_in_progress)).to match_array([3, 1, 2])
        end.to make_database_queries(:count => 1)
      end
    end

    context "with a has_many that includes an order" do
      it "sorts by total" do
        author2 = Author.create_with_books(2)
        author2.create_books(2, :published => true, :rating => 5)
        author0 = Author.create
        author0.create_books(3, :published => true, :rating => 2)
        author1 = Author.create_with_books(1)
        author1.create_books(1, :published => true, :rating => 0)

        expect(Author.order(:total_recently_published_books).pluck(:id))
          .to eq([author1, author2, author0].map(&:id))
        expect(Author.order(:sum_recently_published_books_rating).pluck(:id))
          .to eq([author1, author0, author2].map(&:id))
      end

      it "calculates totals locally" do
        author0 = Author.create
        author0.create_books(2, :published => true, :rating => 2)
        author2 = Author.create_with_books(2)
        author2.create_books(1, :published => true, :rating => 5)

        expect do
          expect(Author.find(author0.id).total_recently_published_books).to eq(2)
          expect(Author.find(author0.id).sum_recently_published_books_rating).to eq(4)
          expect(Author.find(author2.id).total_recently_published_books).to eq(1)
          expect(Author.find(author2.id).sum_recently_published_books_rating).to eq(5)
        end.to make_database_queries(:count => 8)
      end

      it "can bring back totals in primary query" do
        author3 = Author.create_with_books(3)
        author3.create_books(2, :published => true, :rating => 2)
        author1 = Author.create_with_books(1)
        author1.create_books(3, :published => true, :rating => 1)
        author2 = Author.create_with_books(2)
        author2.create_books(1, :published => true, :rating => 5)

        expect do
          cols = %i[id total_recently_published_books sum_recently_published_books_rating]
          author_query = Author.select(*cols).to_a
          expect(author_query).to match_array([author3, author1, author2])
          expect(author_query.map(&:total_recently_published_books)).to match_array([2, 3, 1])
          expect(author_query.map(&:sum_recently_published_books_rating)).to match_array([4, 3, 5])
        end.to make_database_queries(:count => 1)
      end
    end

    context "with a special books class" do
      before do
        class SpecialBook < Book
          default_scope { where(:special => true) }

          self.table_name = 'books'
        end

        # Monkey patching Author for these specs
        class Author < VirtualTotalTestBase
          has_many :special_books,
                   :class_name => "SpecialBook", :foreign_key => "author_id"
          has_many :published_special_books, -> { published },
                   :class_name => "SpecialBook", :foreign_key => "author_id"

          virtual_total :total_special_books, :special_books
          virtual_total :total_special_books_published, :published_special_books
        end
      end

      after do
        Object.send(:remove_const, :SpecialBook)
      end

      context "with a has_many that includes a scope" do
        it "sorts by total" do
          author2 = Author.create_with_books(2)
          author2.create_books(5, :special => true)
          author2.create_books(1, :special => true, :published => true)
          author0 = Author.create
          author0.create_books(2, :special => true)
          author0.create_books(2, :special => true, :published => true)
          author1 = Author.create_with_books(1)

          expect(Author.order(:total_special_books).pluck(:id))
            .to eq([author1, author0, author2].map(&:id))
          expect(Author.order(:total_special_books_published).pluck(:id))
            .to eq([author1, author2, author0].map(&:id))
        end

        it "calculates totals locally" do
          author0 = Author.create
          author0.create_books(2, :special => true)
          author0.create_books(2, :special => true, :published => true)
          author2 = Author.create_with_books(2)
          author2.create_books(5, :special => true)
          author2.create_books(1, :special => true, :published => true)

          expect do
            expect(Author.find(author0.id).total_books).to eq(4)
            expect(Author.find(author0.id).total_special_books).to eq(4)
            expect(Author.find(author0.id).total_special_books_published).to eq(2)
            expect(Author.find(author2.id).total_books).to eq(8)
            expect(Author.find(author2.id).total_special_books).to eq(6)
            expect(Author.find(author2.id).total_special_books_published).to eq(1)
          end.to make_database_queries(:count => 12)
        end

        it "can bring back totals in primary query" do
          author3 = Author.create_with_books(3)
          author3.create_books(4, :published => true)
          author1 = Author.create_with_books(1)
          author1.create_books(2, :special => true)
          author1.create_books(2, :special => true, :published => true)
          author2 = Author.create_with_books(2)
          author2.create_books(5, :special => true)
          author2.create_books(1, :special => true, :published => true)

          expect do
            cols = %i[
              id
              total_books
              total_books_published
              total_special_books
              total_special_books_published
            ]
            author_query = Author.select(*cols).to_a
            expect(author_query).to match_array([author3, author1, author2])
            expect(author_query.map(&:total_books)).to match_array([7, 5, 8])
            expect(author_query.map(&:total_books_published)).to match_array([4, 2, 1])
            expect(author_query.map(&:total_special_books)).to match_array([0, 4, 6])
            expect(author_query.map(&:total_special_books_published)).to match_array([0, 2, 1])
          end.to make_database_queries(:count => 1)
        end
      end
    end
  end

  describe ".virtual_total (with real has_many relation ems#total_vms)" do
    let(:base_model) { Author }
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
      expect do
        ms = mc.select(:id, :total_books)
        expect(ms).to match_array([m3, m2, m1])
        expect(ms.map(&:total_books)).to match_array([3, 2, 1])
      end.to make_database_queries(:count => 1)
    end

    def model_with_children(count)
      Author.create_with_books(count)
    end
  end

  describe ".virtual_total (with virtual relation Author#total_named_books)" do
    let(:base_model) { Author }
    # it can not sort by virtual

    it "calculates totals locally" do
      expect(model_with_children(0).v_total_named_books).to eq(0)
      expect(model_with_children(2).v_total_named_books).to eq(2)
    end

    it "falls back to default when virtual association is not written correctly in ruby" do
      a = model_with_children(0)
      # note: this is breaking the return to return nil. (it should return [] / none)
      # some of our associations (virtual) are broken.
      expect(a).to receive(:named_books).and_return(nil)

      expect(a.v_total_named_books).to eq(0)
    end

    it "is not defined in sql" do
      expect(base_model.attribute_supported_by_sql?(:total_named_books)).to be(false)
    end

    it "alias is not defined in sql" do
      expect(base_model.attribute_supported_by_sql?(:v_total_named_books)).to be(false)
    end

    def model_with_children(count)
      Author.create_with_books(count)
    end
  end

  describe ".virtual_total (with through relation (ems#total_storages)" do
    let(:base_model) { Author }

    it "calculates totals locally" do
      expect(model_with_children(0).total_bookmarks).to eq(0)
      expect(model_with_children(2).total_bookmarks).to eq(4)
    end

    it "calculates totals in primary query" do
      expect(base_model.attribute_supported_by_sql?(:total_bookmarks)).to be(true)

      model_with_children(1) # 2 =  1 book  @ 2 bookmarks each
      model_with_children(0) # 0
      model_with_children(3) # 6 =  3 books @ 2 bookmarks each

      expect do
        expect(base_model.select(:id, :total_bookmarks).order(:total_bookmarks => :desc).map(&:total_bookmarks)).to eq([6, 2, 0])
      end.to make_database_queries(:count => 1)
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
      let(:base_model) { Author }

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
        end.to_not make_database_queries
      end

      def model_with_children(count)
        Author.create_with_books(count).reload
      end
    end
  end

  describe ".virtual_aggregation" do
    context "with a standard has_many" do
      let(:authors) { [author, author2, author3, author4] }
      let(:author) do
        Author.create_with_books(1).tap do |author|
          author.create_books(1, :published => true, :rating => 4)
          author.create_books(1, :published => true, :rating => 2)
          author.create_books(1, :published => true)
        end
      end

      let(:author2) do
        Author.create.tap do |author|
          author.create_books(1, :published => true, :rating => 5)
        end
      end

      let(:author3) { Author.create }
      let(:author4) { Author.create.tap { |a| a.create_books(1, :published => true) } }

      describe ":sum" do
        # NOTE: rails converts the nil to a 0
        it "calculates sum with one off query" do
          authors

          expect do
            expect(authors.map(&:sum_recently_published_books_rating)).to eq([6, 5, 0, 0])
          end.to make_database_queries(:count => 4)
        end

        it "calculates sum from preloaded association" do
          authors.each { |a| a.recently_published_books.load }

          expect do
            expect(authors.map(&:sum_recently_published_books_rating)).to eq([6, 5, nil, nil])
          end.to_not make_database_queries
        end

        it "calculates sum from attribute" do
          authors
          query = Author.select(:id, :sum_recently_published_books_rating).order(:id).load
          expect do
            expect(query.map(&:sum_recently_published_books_rating)).to eq([6, 5, 0, 0])
          end.to_not make_database_queries
        end

        it "calculates sum from attribute (and preloaded association)" do
          authors
          query = Author.includes(:recently_published_books).select(:id, :sum_recently_published_books_rating).order(:id).load
          expect do
            expect(query.map(&:sum_recently_published_books_rating)).to eq([6, 5, 0, 0])
          end.to_not make_database_queries
        end

        it "orders by values with a nil (having the nil (defaulted to 0) first" do
          authors
          query = Author.order(:sum_recently_published_books_rating)
          expect(query.map(&:id)).to eq([author3, author4, author2, author].map(&:id))
        end
      end

      describe ":average" do
        # NOTE: rails converts the nil to a 0
        it "calculates avg with one off query" do
          authors
          expect do
            expect(authors.map(&:average_recently_published_books_rating)).to eq([3, 5, 0, 0])
          end.to make_database_queries(:count => 4)
        end

        it "calculates avg from preloaded association" do
          authors.each { |a| a.recently_published_books.load }

          expect do
            expect(authors.map(&:average_recently_published_books_rating)).to eq([3, 5, 0, 0])
          end.to_not make_database_queries
        end

        it "calculates avg from attribute" do
          authors
          query = Author.select(:id, :average_recently_published_books_rating).order(:id).load
          expect do
            expect(query.map(&:average_recently_published_books_rating)).to eq([3, 5, 0, 0])
          end.to_not make_database_queries
        end

        it "calculates avg from attribute (and preloaded association)" do
          authors
          query = Author.includes(:recently_published_books).select(:id, :average_recently_published_books_rating).order(:id).load
          expect do
            expect(query.map(&:average_recently_published_books_rating)).to eq([3, 5, 0, 0])
          end.to_not make_database_queries
        end
      end

      describe ":maximum" do
        # NOTE: rails converts the nil to a 0
        it "calculates max with one off query" do
          authors

          expect do
            expect(authors.map(&:maximum_recently_published_books_rating)).to eq([4, 5, 0, 0])
          end.to make_database_queries(:count => 4)
        end

        it "calculates max from preloaded association" do
          authors.each { |a| a.recently_published_books.load }

          expect do
            expect(authors.map(&:maximum_recently_published_books_rating)).to eq([4, 5, nil, nil])
          end.to_not make_database_queries
        end

        it "calculates max from attribute" do
          authors
          query = Author.select(:id, :maximum_recently_published_books_rating).order(:id).load
          expect do
            expect(query.map(&:maximum_recently_published_books_rating)).to eq([4, 5, 0, 0])
          end.to_not make_database_queries
        end

        it "calculates max from attribute (and preloaded association)" do
          authors
          query = Author.includes(:recently_published_books).select(:id, :maximum_recently_published_books_rating).order(:id).load
          expect do
            expect(query.map(&:maximum_recently_published_books_rating)).to eq([4, 5, 0, 0])
          end.to_not make_database_queries
        end
      end

      describe ":minimum" do
        # NOTE: rails converts the nil to a 0
        it "calculates min with one off query" do
          authors

          expect do
            expect(authors.map(&:minimum_recently_published_books_rating)).to eq([2, 5, 0, 0])
          end.to make_database_queries(:count => 4)
        end

        it "calculates min from preloaded association" do
          authors.each { |a| a.recently_published_books.load }

          expect do
            expect(authors.map(&:minimum_recently_published_books_rating)).to eq([2, 5, nil, nil])
          end.to_not make_database_queries
        end

        it "calculates min from attribute" do
          authors
          query = Author.select(:id, :minimum_recently_published_books_rating).order(:id).load
          expect do
            expect(query.map(&:minimum_recently_published_books_rating)).to eq([2, 5, 0, 0])
          end.to_not make_database_queries
        end

        it "calculates min from attribute (and preloaded association)" do
          authors
          query = Author.includes(:recently_published_books).select(:id, :minimum_recently_published_books_rating).order(:id).load
          expect do
            expect(query.map(&:minimum_recently_published_books_rating)).to eq([2, 5, 0, 0])
          end.to_not make_database_queries
        end
      end

      it "orders by values with a nil (having the nil (defaulted to 0) first" do
        authors
        query = Author.order(:sum_recently_published_books_rating)
        expect(query.map(&:id)).to eq([author3, author4, author2, author].map(&:id))
      end
    end
  end
end
