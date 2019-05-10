describe ActiveRecord::VirtualAttributes::VirtualIncludes do
  before do
    Author.destroy_all
    Book.destroy_all
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

  # FIX
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

  it "should leverage include for virtual fields" do
    authors = nil
    expect { authors = Author.includes(:books => :author_name).load }.to match_query_limit_of(3)
    expect { expect(authors.first.books.first.author_name).to eq(authors.first.name) }.to match_query_limit_of(0)
  end
end
