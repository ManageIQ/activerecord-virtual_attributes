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
    expect do
      expect(Book.select(:author_name)).to preload_values(:author_name, "bogus")
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /expected:/)
  end

  it "detects values not preloaded" do
    expect(Book).not_to preload_values(:author_name, author_name)
  end

  # even though we said not to preload, still expecting values to match
  it "detects values not preloaded but matching failures" do
    expect do
      expect(Book).not_to preload_values(:author_name, "bogus")
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /expected:/)
  end

  it "detects values not preloaded failure (expecting not preloaded but they were)" do
    expect do
      expect(Book.select(:author_name)).not_to preload_values(:author_name, author_name)
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError, "Unexpectedly preloaded author_name")
  end
end
