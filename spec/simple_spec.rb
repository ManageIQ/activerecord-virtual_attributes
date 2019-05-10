# had some issues determining what was failing in basic rails vs virtual_attributes patched rails
# run:
#
#   tests with STUBS=true bundle exec rspec spec/simple_spec.rb
#
RSpec.describe "Simple query tests" do
  before do
    Book.destroy_all
    Author.create_with_books(3)
  end

  # it "select(:id).includes" do
  #   query = Book.select(:id).includes(:author)
  #   puts query.to_sql if ENV["VERBOSE"].to_s =~ /true/

  #   expect { expect(query.load.size).to eq(3) }.not_to raise_error
  # end

  # surprisingly, this does not complain (but it should)
  # it is because with references, it throws away select
  it "select(:id).includes.references" do
    query = Book.select(:id).includes(:author).references(:author)
    expect { expect(query.load.size).to eq(3) }.not_to raise_error
  end

  # NOTE: author_id is required
  it "select(:id, :author_id).includes" do
    query = Book.select(:id, :author_id).includes(:author)
    expect(query.load.size).to eq(3)
  end

  it "select(:id).includes.references" do
    query = Book.select(:id, :author_id).includes(:author).references(:author)
    expect(query.load.size).to eq(3)
  end
end
