RSpec.describe "preloads_values" do
  before do
    Author.create_with_books(2)
  end

  let(:author_name) { "foo" }
  let(:book_name) { "bar" }

  it "detects values preloaded with a value" do
    expect(Book.select(:author_name)).to preload_values(:author_name, [author_name, author_name])
  end

  it "detects values preloaded (auto converts value to an array)" do
    expect(Book.select(:author_name)).to preload_values(:author_name, author_name)
  end

  it "detects values preloading failure" do
    expect do
      expect(Book).to preload_values(:author_name, author_name)
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError, "Expected to preload author_name but executed 2 queries instead")
  end

  it "detects values matching failure" do
    expect(Book.select(:author_name)).not_to preload_values(:author_name, "bogus")
  end

  it "detects values not preloaded" do
    expect(Book).not_to preload_values(:author_name, author_name)
  end

  # double wammy here. didn't preload, and the values were different as well
  it "detects values not preloaded but matching failures" do
    expect(Book).not_to preload_values(:author_name, "bogus")
  end

  it "detects values not preloaded failure (expecting not preloaded but they were)" do
    expect do
      expect(Book.select(:author_name)).not_to preload_values(:author_name, author_name)
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError, "Unexpectedly preloaded author_name")
  end
end
