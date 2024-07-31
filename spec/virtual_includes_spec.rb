RSpec.describe ActiveRecord::VirtualAttributes::VirtualIncludes do
  before do
    Author.create_with_books(3).books.first.create_bookmarks(2)
  end

  let(:author_name) { "foo" }
  let(:book_name) { "bar" }
  # NOTE: each of the 1 authors has an array of books. so this value is [[Book, Book]]
  let(:named_books) { [Book.where.not(:name => nil).order(:id).load] }

  context "preloads virtual_attribute with select" do
    it "preloads virtual_attribute (:uses => {:author})" do
      expect(Book.select(:author_name)).to preload_values(:author_name, author_name)
      expect(Book.select(:author_name2)).to preload_values(:author_name2, author_name)
      expect(Book.select(:id, :author_name)).to preload_values(:author_name, author_name)
    end
  end

  it "doesn't preload without includes" do
    expect(Author).not_to preload_values(:first_book_name, book_name)
    expect(Book).not_to preload_values(:author_name, author_name)
  end

  context "preloads virtual_attributes with includes" do
    it "preloads virtual_attribute (:uses => nil) (with a NO OP)" do
      expect(Author.includes(:nick_or_name)).to preload_values(:nick_or_name, author_name)
      expect(Author.includes([:nick_or_name])).to preload_values(:nick_or_name, author_name)
      expect(Author.includes(:nick_or_name => {})).to preload_values(:nick_or_name, author_name)
    end

    it "preloads virtual_attribute (:uses => [:book])" do
      expect(Author.includes(:first_book_name)).to preload_values(:first_book_name, book_name)
      expect(Author.includes([:first_book_name])).to preload_values(:first_book_name, book_name)
      expect(Author.includes(:first_book_name => {})).to preload_values(:first_book_name, book_name)
    end

    it "preloads virtual_attribute (delegate defines :uses => :author)" do
      expect(Book.includes(:author_name)).to preload_values(:author_name, author_name)
      expect(Book.includes([:author_name])).to preload_values(:author_name, author_name)
      expect(Book.includes(:author_name => {})).to preload_values(:author_name, author_name)
    end

    it "preloads virtual_attribute (:uses => :author, :uses => :author)" do
      expect(Book.includes(:author_name, :author_name2)).to preload_values(:author_name, author_name)
      expect(Book.includes(:author_name2 => {})).to preload_values(:author_name, author_name)
    end

    it "preloads virtual_attribute (:uses => :upper_author_name) (:uses => :author_name)" do
      expect(Book.includes(:upper_author_name_def)).to preload_values(:upper_author_name_def, author_name.upcase)
      expect(Book.includes([:upper_author_name_def])).to preload_values(:upper_author_name_def, author_name.upcase)
      expect(Book.includes(:upper_author_name_def => {})).to preload_values(:upper_author_name_def, author_name.upcase)
    end

    it "preloads virtual_attribute (multiple)" do
      expect(Author.includes(:nick_or_name).includes(:first_book_name)).to preload_values(:first_book_name, book_name)
      expect(Author.includes([:nick_or_name, :first_book_name])).to preload_values(:first_book_name, book_name)
      expect(Author.includes(:nick_or_name => {}, :first_book_name => {})).to preload_values(:first_book_name, book_name)
    end

    it "preloads virtual_attributes dups" do
      expect(Author.includes(:total_named_books).includes(:first_book_author_name)).to preload_values(:first_book_author_name, author_name)
    end

    it "preloads virtual_attribute (:uses => {:book => :author_name})" do
      expect(Author.includes(:first_book_author_name)).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes([:first_book_author_name])).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:first_book_author_name => {})).to preload_values(:first_book_author_name, author_name)
    end

    it "preloads virtual_attributes (:uses => {:first_book_author_name}) which (:uses => {:books => :author_name})" do
      expect(Author.includes(:upper_first_book_author_name)).to preload_values(:upper_first_book_author_name, author_name.upcase)
      expect(Author.includes([:upper_first_book_author_name])).to preload_values(:upper_first_book_author_name, author_name.upcase)
      expect(Author.includes(:upper_first_book_author_name => {})).to preload_values(:upper_first_book_author_name, author_name.upcase)
    end

    it "preloads through polymorphic (polymorphic => virtual_attribute)" do
      books = Book.includes(:author_or_bookmark => :total_books).load
      expect { expect(books.map { |b| b.author_or_bookmark.total_books }).to eq([3, 3, 3]) }.to_not make_database_queries
    end

    it "preloads through virtual_has_many (virtual_has_many => virtual_attribute)" do
      authors = Author.includes(:named_books => :author_name).load
      expect do
        expect(authors.first.named_books.map(&:author_name)).to eq([author_name] * 3)
      end.to_not make_database_queries
    end

    it "preloads habtm" do
      co_a = Author.create
      books = Book.all.to_a
      books.each { |book| co_a.co_books << book }

      expect(Author.includes(:co_books).find(co_a.id)).to preload_values(:co_books, books)
    end

    it "uses included associations" do
      expect(Author.includes(:books => :author)).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => {:author => {}})).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => :author_name)).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => {:author_name => {}})).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(Author.virtual_includes(:first_book_author_name))).to preload_values(:first_book_author_name, author_name)
    end

    it "counts" do
      expect { expect(Author.includes(:books => :author_name).count).to eq(1) }.not_to raise_error
    end
  end

  # references follow a different path than just includes
  context "preloads virtual_attribute with includes.references" do
    it "preloads virtual_attribute (:uses => nil) (with a NO OP)" do
      expect(Author.includes(:nick_or_name).references(:nick_or_name)).to preload_values(:nick_or_name, author_name)
      expect(Author.includes([:nick_or_name]).references(:nick_or_name)).to preload_values(:nick_or_name, author_name)
      expect(Author.includes(:nick_or_name => {}).references(:nick_or_name)).to preload_values(:nick_or_name, author_name)
    end

    it "preloads virtual_attribute (:uses => :book)" do
      expect(Author.includes(:first_book_name).references(:first_book_name)).to preload_values(:first_book_name, book_name)
      expect(Author.includes([:first_book_name]).references(:first_book_name)).to preload_values(:first_book_name, book_name)
      expect(Author.includes(:first_book_name => {}).references(:first_book_name)).to preload_values(:first_book_name, book_name)
    end

    it "preloads virtual_attribute (delegate defines :uses => :author)" do
      expect(Book.includes(:author_name).references(:author_name)).to preload_values(:author_name, author_name)
      expect(Book.includes([:author_name]).references(:author_name)).to preload_values(:author_name, author_name)
      expect(Book.includes(:author_name => {}).references(:author_name)).to preload_values(:author_name, author_name)
    end

    it "preloads virtual_attribute (:uses => :upper_author_name) (:uses => :author_name)" do
      expect(Book.includes(:upper_author_name_def).references(:upper_author_name_def)).to preload_values(:upper_author_name_def, author_name.upcase)
      expect(Book.includes([:upper_author_name_def]).references(:upper_author_name_def)).to preload_values(:upper_author_name_def, author_name.upcase)
      expect(Book.includes(:upper_author_name_def => {}).references(:upper_author_name_def)).to preload_values(:upper_author_name_def, author_name.upcase)
    end

    it "preloads virtual_attribute (multiple)" do
      expect(Author.includes(:nick_or_name).includes(:first_book_name).references(:nick_or_name, :first_book_name)).to preload_values(:first_book_name, book_name)
      expect(Author.includes([:nick_or_name, :first_book_name]).references(:nick_or_name, :first_book_name)).to preload_values(:first_book_name, book_name)
      expect(Author.includes(:nick_or_name => {}, :first_book_name => {}).references(:nick_or_name, :first_book_name)).to preload_values(:first_book_name, book_name)
    end

    it "preloads virtual_reflections (multiple overlap hash)" do
      expect(Author.includes(:books_with_authors => {}, :books => {}).references(:books)).to preload_values(:books_with_authors, named_books)
      expect(Author.includes(:books).includes(:books => {:author => {}}).references(:books)).to preload_values(:books_with_authors, named_books)
      expect(Author.includes(:books => {:author => {}}).includes(:books => {}).references(:books)).to preload_values(:books_with_authors, named_books)
    end

    it "preloads virtual_attributes dups" do
      expect(Author.includes(:books => :author, :books_with_authors => {}).references(:first_book_author_name)).to preload_values(:first_book_author_name, author_name)
    end

    it "preloads virtual_attribute (:uses => {:book => :author_name})" do
      expect(Author.includes(:first_book_author_name).references(:first_book_author_name)).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes([:first_book_author_name]).references(:first_book_author_name)).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:first_book_author_name => {}).references(:first_book_author_name)).to preload_values(:first_book_author_name, author_name)
    end

    it "preloads virtual_attributes (:uses => {:first_book_author_name}) which (:uses => {:books => :author_name})" do
      expect(Author.includes(:upper_first_book_author_name).references(:first_book_author_name)).to preload_values(:upper_first_book_author_name, author_name.upcase)
      expect(Author.includes([:upper_first_book_author_name]).references(:first_book_author_name)).to preload_values(:upper_first_book_author_name, author_name.upcase)
      expect(Author.includes(:upper_first_book_author_name => {}).references(:first_book_author_name)).to preload_values(:upper_first_book_author_name, author_name.upcase)
    end

    it "doesn't preloads through polymorphic" do
      expect do
        Book.includes(:author_or_bookmark => :total_books).references(:author_name).load
      end.to raise_error(ActiveRecord::EagerLoadPolymorphicError)
    end

    it "uses included associations" do
      expect(Author.includes(:books => :author).references(:books, :authors)).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => [:author]).references(:books, :authors)).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => {:author => {}}).references(:books, :authors)).to preload_values(:first_book_author_name, author_name)

      expect(Author.includes(:books => :author_name).references(:books)).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => [:author_name]).references(:books)).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => {:author_name =>{}}).references(:books)).to preload_values(:first_book_author_name, author_name)
    end

    it "uses included fields" do
      expect(Author.includes(:books => :author_name).references(:books)).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => [:author_name]).references(:books)).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => {:author_name => {}}).references(:books)).to preload_values(:first_book_author_name, author_name)
    end

    it "uses preloaded fields" do
      expect(Author.includes(:books => :author_name).references(:books)).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => [:author_name]).references(:books)).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => {:author_name => {}}).references(:books)).to preload_values(:first_book_author_name, author_name)
      inc = Author.virtual_includes(:first_book_author_name)
      expect(Author.includes(inc).references(:books)).to preload_values(:first_book_author_name, author_name)
    end

    it "detects errors" do
      expect { Author.includes(:books).references(:books).load }.not_to raise_error
      expect { Author.includes(:invalid).references(:books).load }.to raise_error(ActiveRecord::ConfigurationError)
      expect { Author.includes(:books => :invalid).references(:books).load }.to raise_error(ActiveRecord::ConfigurationError)
      expect { Author.includes(:books => [:invalid]).references(:books).load }.to raise_error(ActiveRecord::ConfigurationError)
      expect { Author.includes(:books => {:invalid => {}}).references(:books).load }.to raise_error(ActiveRecord::ConfigurationError)
    end

    it "counts" do
      expect { expect(Author.includes(:books => :author_name).references(:books).count).to eq(1) }.not_to raise_error
    end
  end

  context "preloads virtual_attribute with select.includes.references" do
    # select().references().includes() for a single field never worked well together.
    #
    # brings back column (author_name) in subselect
    # brings back (via joins and selects) author record
    #
    # issues:
    #
    # 1. It brings back authors table for no reason. The author_name subselect is plenty.
    # 2. The main query SELECT does not have author_id which is needed to join to the authors table.
    #
    # rails 6.0 brings back all of books.*, authors.*, so the query works
    # rails 6.1 brings back books.id, authors.*, (missing author_id) and blows up.
    xit "preloads virtual_attribute (:uses => {:book => :author_name})" do
      expect(Book.select(:author_name).includes(:author_name).references(:author_name)).to preload_values(:author_name, author_name)
    end
  end

  it "preloads virtual_attribute in :include when :conditions are also present in calculations" do
    expect(Book.includes([:author_name, :author]).references(:author).where("authors.name = '#{author_name}'")).to preload_values(:author_name, author_name)
    expect(Book.includes([:author_name, :author]).references(:author).where(:authors => {:name => author_name})).to preload_values(:author_name, author_name)
    # Disable Rails/WhereNot because we are testing this specific use case
    # rubocop:disable Rails/WhereNot
    expect(Book.includes([:author_name, :author]).references(:author).where("authors.id IS NOT NULL")).to preload_values(:author_name, author_name)
    # rubocop:enable Rails/WhereNot
    expect(Book.includes([:author_name, :author]).references(:author).where.not(:authors => {:id => nil})).to preload_values(:author_name, author_name)
  end

  context "preload virtual_attribute with preload" do
    it "preloads attribute (:uses => :book)" do
      expect(Author.preload(:total_books)).to preload_values(:total_books, 3)
    end

    it "double preloads (with some nulls in the data)" do
      Book.create

      books = Book.order(:id).includes(:author).to_a
      expect(books.last.author).to be_nil # the book just created does not have an author

      # the second time preloading throws an error
      preloaded(books, :author => :books)
      expect(books.size).to be(4)
    end
  end

  context "preloads virtual_attribute with preloader" do
    it "preloads attribute (:uses => :book)" do
      expect(preloaded(Author.all.to_a, :total_books)).to preload_values(:total_books, 3)
    end

    it "preloads virtual_attribute (:uses => nil) (with a NO OP)" do
      expect(preloaded(Author.all.to_a, :nick_or_name)).to preload_values(:nick_or_name, author_name)
    end

    it "preloads virtual_attribute (:uses => :book)" do
      expect(preloaded(Author.all.to_a, :first_book_name)).to preload_values(:first_book_name, book_name)
    end

    it "preloads virtual_attribute (delegate defines :uses => :author)" do
      expect(preloaded(Book.all.to_a, :author_name)).to preload_values(:author_name, author_name)
    end

    it "preloads virtual_attribute (:uses => :upper_author_name) (:uses => :author_name)" do
      expect(preloaded(Book.all.to_a, :upper_author_name_def)).to preload_values(:upper_author_name_def, author_name.upcase)
    end

    it "preloads virtual_attribute (multiple)" do
      expect(preloaded(Author.all.to_a, [:nick_or_name, :first_book_name])).to preload_values(:first_book_name, book_name)
    end

    it "preloads virtual_reflections (multiple overlap hash)" do
      expect(preloaded(Author.all.to_a, :books_with_authors => {}, :books => {})).to preload_values(:books_with_authors, named_books)
    end

    it "preloads virtual_attributes dups" do
      expect(preloaded(Author.all.to_a, :books => :author, :books_with_authors => {})).to preload_values(:first_book_author_name, author_name)
    end

    it "preloads virtual_attribute (:uses => {:book => :author_name})" do
      expect(preloaded(Author.all.to_a, :first_book_author_name)).to preload_values(:first_book_author_name, author_name)
    end

    it "preloads virtual_attributes (:uses => {:first_book_author_name}) which (:uses => {:books => :author_name})" do
      expect(preloaded(Author.all.to_a, :upper_first_book_author_name)).to preload_values(:upper_first_book_author_name, author_name.upcase)
    end

    it "preloads through association" do
      books = preloaded(Book.all.to_a, :author => :total_books)
      expect { books.map { |book| book.author.total_books } }.to_not make_database_queries
    end

    it "doesn't preloads through polymorphic" do ##
      # not sure what is expected to happen for preloading a column (that is not standard rails) use select instead
      a = preloaded(Book.all.to_a, :author_or_bookmark => :total_books)
      expect { a.map { |book| book.author_or_bookmark.total_books } }.to_not make_database_queries
    end

    it "uses included associations" do
      expect(preloaded(Author.all.to_a, :books => :author)).to preload_values(:first_book_author_name, author_name)
      expect(preloaded(Author.all.to_a, :books => :author_name)).to preload_values(:first_book_author_name, author_name)
    end

    it "uses included fields" do
      expect(preloaded(Author.all.to_a, :books => :author_name)).to preload_values(:first_book_author_name, author_name)
    end

    it "uses preloaded fields" do
      expect(preloaded(Author.all.to_a, :books => :author_name)).to preload_values(:first_book_author_name, author_name)
    end
  end

  context "preloads virtual_reflection with includes" do
    it "doesn't preload without includes" do
      expect(Author).not_to preload_values(:named_books, named_books)
    end

    it "preloads virtual_reflection (:uses => :books)" do
      expect(Author.includes(:named_books)).to preload_values(:named_books, named_books)
      expect(Author.includes([:named_books])).to preload_values(:named_books, named_books)
      expect(Author.includes(:named_books => {})).to preload_values(:named_books, named_books)
    end

    it "preloads virtual_reflection (:uses => {:books => :author_name})" do
      expect(Author.includes(:books_with_authors)).to preload_values(:books_with_authors, named_books)
      expect(Author.includes([:books_with_authors])).to preload_values(:books_with_authors, named_books)
      expect(Author.includes(:books_with_authors => {})).to preload_values(:books_with_authors, named_books)
    end

    it "preloads virtual_reflection (multiple)" do
      expect(Author.includes([:named_books, :bookmarks])).to preload_values(:named_books, named_books)
      expect(Author.includes(:named_books => {}, :bookmarks => :book)).to preload_values(:named_books, named_books)
    end

    it "preloads virtual_reflections (multiple overlap hash)" do
      expect(Author.includes(:books_with_authors => {}, :books => {})).to preload_values(:books_with_authors, named_books)
      expect(Author.includes(:books => {}).includes(:books => {:author => {}})).to preload_values(:books_with_authors, named_books)
      expect(Author.includes(:books => {:author => {}}).includes(:books => {})).to preload_values(:books_with_authors, named_books)
    end

    it "preloads virtual_reflection(:uses => :books => :bookmarks) (nothing virtual)" do
      bookmarked_book = Author.first.books.first
      expect(Author.includes(:book_with_most_bookmarks)).to preload_values(:book_with_most_bookmarks, bookmarked_book)
    end

    it "preloads virtual_reflection(:uses => :books => :bookmarks, :uses => :books) (multiple overlapping relations)" do
      bookmarked_book = Author.first.books.first
      expect(Author.includes(:book_with_most_bookmarks, :books)).to preload_values(:book_with_most_bookmarks, bookmarked_book)
    end
  end

  context "preloads virtual_reflection with includes.references" do
    it "preloads virtual_reflection (:uses => [:books])" do
      expect(Author.includes(:named_books).references(:named_books)).to preload_values(:named_books, named_books)
      expect(Author.includes([:named_books]).references(:named_books)).to preload_values(:named_books, named_books)
      expect(Author.includes(:named_books => {}).references(:named_books)).to preload_values(:named_books, named_books)
    end

    it "preloads virtual_reflection (:uses => {:books => :author_name})" do
      expect(Author.includes(:books_with_authors).references(:books_with_authors)).to preload_values(:books_with_authors, named_books)
      expect(Author.includes([:books_with_authors]).references(:books_with_authors)).to preload_values(:books_with_authors, named_books)
      expect(Author.includes(:books_with_authors => {}).references(:books_with_authors)).to preload_values(:books_with_authors, named_books)
    end

    it "preloads virtual_reflection(:uses => :books => :bookmarks) (nothing virtual)" do
      bookmarked_book = Author.first.books.first
      expect(Author.includes(:book_with_most_bookmarks).references(:book_with_most_bookmarks)).to preload_values(:book_with_most_bookmarks, bookmarked_book)
    end

    it "preloads virtual_reflection(:uses => :books => :bookmarks, :books)" do
      bookmarked_book = Author.first.books.first
      expect(Author.includes([{:book_with_most_bookmarks => {}}, :books]).references(:book_with_most_bookmarks, :books)).to preload_values(:book_with_most_bookmarks, bookmarked_book)
    end

    it "preloads virtual_reflection(:uses => :books => :bookmarks, :books) (nothing virtual)" do
      other_author_name = "Drew"
      other_author = Author.create(:name => other_author_name)
      Author.first.books.first.co_authors << other_author

      # first author has [co-author], second author (aka other_author) has none
      expect { Author.includes(:famous_co_authors).references(:famous_co_authors) }.to preload_values(:famous_co_authors, [[other_author], []])
    end
  end

  context "preloads virtual_reflection with preloader" do
    it "preloads virtual_reflection (:uses => :books)" do
      expect(preloaded(Author.all.to_a, :named_books)).to preload_values(:named_books, named_books)
    end

    it "preloads virtual_reflection (:uses => {:books => :author_name})" do
      expect(preloaded(Author.all.to_a, :books_with_authors)).to preload_values(:books_with_authors, named_books)
    end

    it "preloads virtual_reflection (multiple)" do
      expect(preloaded(Author.all.to_a, [:named_books, :bookmarks])).to preload_values(:named_books, named_books)
    end

    it "preloads virtual_reflections (multiple overlap hash)" do
      expect(preloaded(Author.all.to_a, [:books_with_authors, :books])).to preload_values(:books_with_authors, named_books)
      expect(preloaded(Author.all.to_a, :books => :author)).to preload_values(:books_with_authors, named_books)
    end

    it "preloads virtual_reflection(:uses => :books => :bookmarks) (nothing virtual)" do
      bookmarked_book = Author.first.books.first
      expect(preloaded(Author.all.to_a, :book_with_most_bookmarks)).to preload_values(:book_with_most_bookmarks, bookmarked_book)
    end
  end

  context ".merge_includes" do
    it "merges when first is blank" do
      first  = {}
      second = {:key => {}}
      result = {:key => {}}
      expect(Author.merge_includes(first, second)).to eq(result)
    end

    it "merges when second is blank" do
      first  = {:key => {}}
      second = {}
      result = {:key => {}}
      expect(Author.merge_includes(first, second)).to eq(result)
    end

    it "keeps other keys" do
      first  = {:other1 => {}}
      second = {:other2 => {}}
      result = {:other1 => {}, :other2 => {}}
      expect(Author.merge_includes(first, second)).to eq(result)
    end

    it "merges blank, blank" do
      first  = {:key => {}}
      second = {:key => {}}
      result = {:key => {}}
      expect(Author.merge_includes(first, second)).to eq(result)
    end

    it "merges blank, hash" do
      first  = {:key => {}}
      second = {:key => {:more2 => {}}}
      result = {:key => {:more2 => {}}}
      expect(Author.merge_includes(first, second)).to eq(result)
    end

    it "merges hash, blank" do
      first  = {:key => {:more1 => {}}}
      second = {:key => {}}
      result = {:key => {:more1 => {}}}
      expect(Author.merge_includes(first, second)).to eq(result)
    end

    it "merges hash, hash - 1 level only" do
      first  = {:key => {:more1 => {}}}
      second = {:key => {:more2 => {}}}
      result = {:key => {:more1 => {}, :more2 => {}}}
      expect(Author.merge_includes(first, second)).to eq(result)
    end

    it "merges hash(hash), hash(symbol)" do
      first  = {:key => {:more1 => {}}}
      second = {:key => :more2}
      result = {:key => {:more1 => {}, :more2 => {}}}
      expect(Author.merge_includes(first, second)).to eq(result)
    end

    it "merges hash(hash), hash(array)" do
      first  = {:key => {:more1 => {}}}
      second = {:key => [:more2]}
      result = {:key => {:more1 => {}, :more2 => {}}}
      expect(Author.merge_includes(first, second)).to eq(result)
    end

    it "merges 2 overlapping hashes - 2 levels" do
      first  = {:key => {:more => {:third => {:fourth1 => {}}}}}
      second = {:key => {:more => {:third => {:fourth2 => true}}}}
      result = {:key => {:more => {:third => {:fourth1 => {}, :fourth2 => true}}}}
      expect(Author.merge_includes(first, second)).to eq(result)
    end

    it "merges hash, symbol" do
      first  = {:key => {:more => {}}}
      second = :key
      result = {:key => {:more => {}}}
      expect(Author.merge_includes(first, second)).to eq(result)
    end

    it "merges hash, string" do
      first  = {:key => {:more => {}}}
      second = "key"
      result = {:key => {:more => {}}}
      expect(Author.merge_includes(first, second)).to eq(result)
    end

    it "merges hash, nil" do
      first  = {:key => {:more => {}}}
      second = nil
      result = {:key => {:more => {}}}
      expect(Author.merge_includes(first, second)).to eq(result)
    end

    it "merges hash, array" do
      first  = {:key => {:more => {}}}
      second = [:key]
      result = {:key => {:more => {}}}
      expect(Author.merge_includes(first, second)).to eq(result)
    end
  end

  context "supports left_joins with virtual attributes" do
    it "supports virtual includes in left joins" do
      expect { Book.left_joins(:author_name).where.not(:authors => {:name => nil}).load }.not_to raise_error
    end
  end

  context ".replace_virtual_field (private)" do
    # TODO: produce {:books => :bookmarks} without the extra :books
    it "handles deep includes(:uses => :books => :bookmarks)" do
      expect(Author.replace_virtual_fields([:book_with_most_bookmarks, :books])).to eq([{:books => :bookmarks}, :books])
      expect(Author.replace_virtual_fields(["book_with_most_bookmarks", "books"])).to eq([{:books => :bookmarks}, :books])
      expect(Author.replace_virtual_fields([{:book_with_most_bookmarks => {}}, :books])).to eq([{:books => :bookmarks}, :books])
      expect(Author.replace_virtual_fields([{:book_with_most_bookmarks => {}}, {:books => {}}])).to eq([{:books => :bookmarks}, :books])
    end

    it "handles hash form of delegates" do
      expect(Book.replace_virtual_fields([{:author_name => {}}, {:author_name2 => {}}])).to eq([:author, :author])
    end

    it "handles non-'includes' virtual_attributes" do
      expect(Author.replace_virtual_fields(:nick_or_name)).to eq(nil)
      expect(Author.replace_virtual_fields([:nick_or_name])).to eq(nil)
      expect(Author.replace_virtual_fields(:nick_or_name => {})).to eq(nil)
    end

    it "handles deep includes with va indirect uses(:uses => :books => :bookmarks)" do
      expect(Author.replace_virtual_fields(:famous_co_authors => {})).to eq({:books => {:bookmarks => {}, :co_authors => {}}})
    end

    it "handles arrays" do
      value = Author.includes(:named_books).includes_values
      expect(Author.replace_virtual_fields(value)).to eq(:books)
    end
  end

  def preloaded(records, associations, preload_scope = nil)
    # Rails 7+ interface, see rails commit: e3b9779cb701c63012bc1af007c71dc5a888d35a
    ActiveRecord::Associations::Preloader.new(:records => records, :associations => associations, :scope => preload_scope).call
    records
  end
end
