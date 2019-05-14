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

    it "preloads virtual_attribute (multiple)" do
      expect(Author.includes(:nick_or_name).includes(:first_book_name)).to preload_values(:first_book_name, book_name)
      expect(Author.includes([:nick_or_name, :first_book_name])).to preload_values(:first_book_name, book_name)
      expect(Author.includes(:nick_or_name => {}, :first_book_name => {})).to preload_values(:first_book_name, book_name)
    end

    it "preloads virtual_attribute (:uses => {:book => :author_name})" do
      expect(Author.includes(:first_book_author_name)).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes([:first_book_author_name])).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:first_book_author_name => {})).to preload_values(:first_book_author_name, author_name)
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
      expect(Author.includes(:nick_or_name).references(:nick_or_name => {})).to preload_values(:nick_or_name, author_name)
      expect(Author.includes([:nick_or_name]).references(:nick_or_name => {})).to preload_values(:nick_or_name, author_name)
      expect(Author.includes(:nick_or_name => {}).references(:nick_or_name => {})).to preload_values(:nick_or_name, author_name)
    end

    it "preloads virtual_attribute (:uses => :book)" do
      skip("AR 5.1 not including properly") if ActiveRecord.version.to_s >= "5.1"
      expect(Author.includes(:first_book_name).references(:first_book_name => {})).to preload_values(:first_book_name, book_name)
      expect(Author.includes([:first_book_name]).references(:first_book_name => {})).to preload_values(:first_book_name, book_name)
      expect(Author.includes(:first_book_name => {}).references(:first_book_name => {})).to preload_values(:first_book_name, book_name)
    end

    it "preloads virtual_attribute (delegate defines :uses => :author)" do
      skip("AR 5.1 not including properly") if ActiveRecord.version.to_s >= "5.1"
      expect(Book.includes(:author_name).references(:author_name => {})).to preload_values(:author_name, author_name)
      expect(Book.includes([:author_name]).references(:author_name => {})).to preload_values(:author_name, author_name)
      expect(Book.includes(:author_name => {}).references(:author_name => {})).to preload_values(:author_name, author_name)
    end

    it "preloads virtual_attribute (multiple)" do
      skip("AR 5.1 not including properly") if ActiveRecord.version.to_s >= "5.1"
      expect(Author.includes(:nick_or_name).includes(:first_book_name).references(:nick_or_name => {}, :first_book_name => {})).to preload_values(:first_book_name, book_name)
      expect(Author.includes([:nick_or_name, :first_book_name]).references(:nick_or_name => {}, :first_book_name => {})).to preload_values(:first_book_name, book_name)
      expect(Author.includes(:nick_or_name => {}, :first_book_name => {}).references(:nick_or_name => {}, :first_book_name => {})).to preload_values(:first_book_name, book_name)
    end

    it "preloads virtual_attribute (:uses => {:book => :author_name})" do
      skip("AR 5.1 not including properly") if ActiveRecord.version.to_s >= "5.1"
      expect(Author.includes(:first_book_author_name).references(:first_book_author_name => {})).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes([:first_book_author_name]).references(:first_book_author_name => {})).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:first_book_author_name => {}).references(:first_book_author_name => {})).to preload_values(:first_book_author_name, author_name)
    end

    it "uses included associations" do
      skip("AR 5.1 not including properly") if ActiveRecord.version.to_s >= "5.1"
      expect(Author.includes(:books => :author).references(:books => {:author => {}})).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => [:author]).references(:books => {:author => {}})).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => {:author => {}}).references(:books => {:author => {}})).to preload_values(:first_book_author_name, author_name)

      expect(Author.includes(:books => :author_name).references(:books => {:author_name => {}})).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => [:author_name]).references(:books => {:author_name => {}})).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => {:author_name =>{}}).references(:books => {:author_name => {}})).to preload_values(:first_book_author_name, author_name)
    end

    it "uses included fields" do
      skip("AR 5.1 not including properly") if ActiveRecord.version.to_s >= "5.1"
      expect(Author.includes(:books => :author_name).references(:books => {:author_name => {}})).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => [:author_name]).references(:books => {:author_name => {}})).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => {:author_name => {}}).references(:books => {:author_name => {}})).to preload_values(:first_book_author_name, author_name)
    end

    it "uses preloaded fields" do
      skip("AR 5.1 not including properly") if ActiveRecord.version.to_s >= "5.1"
      expect(Author.includes(:books => :author_name).references(:books => {:author_name => {}})).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => [:author_name]).references(:books => {:author_name => {}})).to preload_values(:first_book_author_name, author_name)
      expect(Author.includes(:books => {:author_name => {}}).references(:books => {:author_name => {}})).to preload_values(:first_book_author_name, author_name)
      inc = Author.virtual_includes(:first_book_author_name)
      expect(Author.includes(inc).references(inc)).to preload_values(:first_book_author_name, author_name)
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
      skip("AR 5.1 not including properly") if ActiveRecord.version.to_s >= "5.1"
      expect(Book.select(:author_name).includes(:author_name).references(:author_name)).to preload_values(:author_name, author_name)
    end
  end

  it "preloads virtual_attribute in :include when :conditions are also present in calculations" do
    skip("AR 5.1 not including properly") if ActiveRecord.version.to_s >= "5.1"
    expect(Book.includes([:author_name, :author]).references(:author).where("authors.name = '#{author_name}'")).to preload_values(:author_name, author_name)
    expect(Book.includes([:author_name, :author]).references(:author).where("authors.id IS NOT NULL")).to preload_values(:author_name, author_name)
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

    it "preloads virtual_reflectin (multiple)" do
      expect(Author.includes([:named_books, :bookmarks])).to preload_values(:named_books, named_books)
      expect(Author.includes(:named_books => {}, :bookmarks => :book)).to preload_values(:named_books, named_books)
    end
  end

  context "preloads virtual_reflection with includes.references" do
    it "preloads virtual_reflection (:uses => [:books])" do
      skip("AR 5.1 not including properly") if ActiveRecord.version.to_s >= "5.1"
      expect(Author.includes(:named_books).references(:named_books => {})).to preload_values(:named_books, named_books)
      expect(Author.includes([:named_books]).references(:named_books => {})).to preload_values(:named_books, named_books)
      expect(Author.includes(:named_books => {}).references(:named_books => {})).to preload_values(:named_books, named_books)
    end

    it "preloads virtual_reflection (:uses => {:books => :author_name})" do
      skip("AR 5.1 not including properly") if ActiveRecord.version.to_s >= "5.1"
      expect(Author.includes(:books_with_authors).references(:books_with_authors => {})).to preload_values(:books_with_authors, named_books)
      expect(Author.includes([:books_with_authors]).references(:books_with_authors => {})).to preload_values(:books_with_authors, named_books)
      expect(Author.includes(:books_with_authors => {}).references(:books_with_authors => {})).to preload_values(:books_with_authors, named_books)
    end
  end
end
