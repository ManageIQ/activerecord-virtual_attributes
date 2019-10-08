describe ActiveRecord::VirtualAttributes::VirtualIncludes do
  before do
    Author.destroy_all
    Book.destroy_all
    Author.create_with_books(3).books.first.create_bookmarks(2)
  end

  let(:author_name) { "foo" }
  let(:book_name) { "bar" }
  # NOTE: each of the 1 authors has an array of books. so this value is [[Book, Book]]
  let(:named_books) { [Book.where.not(:name => nil).order(:id).load] }

  context "preloads virtual_attribute with select" do
    it "preloads virtual_attribute (:uses => {:author})" do
      expect(Book.select(:author_name)).to preload_values(:author_name, author_name)
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
      expect { expect(books.map { |b| b.author_or_bookmark.total_books }).to eq([3, 3, 3]) }.to match_query_limit_of(0)
    end

    it "preloads through virtual_has_many (virtual_has_many => virtual_attribute)" do
      authors = Author.includes(:named_books => :author_name).load
      expect do
        expect(authors.first.named_books.map(&:author_name)).to eq([author_name] * 3)
      end.to match_query_limit_of(0)
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
  end

  context "preloads virtual_attribute with select.includes.references" do
    it "preloads virtual_attribute (:uses => {:book => :author_name})" do
      expect(Book.select(:author_name).includes(:author_name).references(:author_name)).to preload_values(:author_name, author_name)
    end
  end

  it "preloads virtual_attribute in :include when :conditions are also present in calculations" do
    expect(Book.includes([:author_name, :author]).references(:author).where("authors.name = '#{author_name}'")).to preload_values(:author_name, author_name)
    expect(Book.includes([:author_name, :author]).references(:author).where("authors.id IS NOT NULL")).to preload_values(:author_name, author_name)
  end

  context "preload virtual_attribute with preload" do
    it "preloads attribute (:uses => :book)" do
      expect(Author.preload(:total_books)).to preload_values(:total_books, 3)
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
      expect { books.map(&:author).map(&:total_books) }.to match_query_limit_of(0)
    end

    it "doesn't preloads through polymorphic" do ##
      # not sure what is expected to happen for preloading a column (that is not standard rails) use select instead
      a = preloaded(Book.all.to_a, :author_or_bookmark => :total_books)
      expect { a.map(&:author_or_bookmark).map(&:total_books) }.to match_query_limit_of(0)
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

    it "ignores errors" do
      expect { Author.includes(:invalid).load }.not_to raise_error #(ActiveRecord::ConfigurationError)
      expect { Author.includes(:books => :invalid).load }.not_to raise_error #(ActiveRecord::ConfigurationError)
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
  end

  context "supports left_joins with virtual attributes" do
    it "doesn't freak when virtual attribute in " do
      # sorry, :author_name will not be available
      # in that case, just .where.not(:author_name => nil) - no need for left_joins
      expect { Book.left_joins(:author_name).where.not(:authors => {:name => nil}).load }.not_to raise_error
    end
  end

  def preloaded(records, associations, preload_scope = nil)
    preloader = ActiveRecord::Associations::Preloader.new
    preloader.preload(records, associations, preload_scope)
    records
  end
end
