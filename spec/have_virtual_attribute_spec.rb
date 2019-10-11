RSpec.describe "have_virtual_attribute" do
  it "detects virtual attribute" do
    expect(Author).to have_virtual_attribute(:nick_or_name)
  end

  it "detects virtual attribute failure" do
    expect do
      expect(Author).not_to have_virtual_attribute(:nick_or_name)
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /not have virtual column/)
  end

  it "detects virtual attribute with type" do
    expect(Author).to have_virtual_attribute(:nick_or_name, :string)
  end

  it "detects incorrect type" do
    expect(Author).not_to have_virtual_attribute(:nick_or_name, :integer)
  end

  it "detects incorrect type failure" do
    expect do
      expect(Author).to have_virtual_attribute(:nick_or_name, :integer)
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /to have virtual column/)
  end

  it "detects virtual attribute" do
    expect(Author).to have_virtual_attribute(:nick_or_name, :string)
  end

  it "detects an attribute is not virtual" do
    expect(Author).not_to have_virtual_attribute(:name, :string)
  end

  it "detects missing virtual attribute" do
    expect(Author).not_to have_virtual_attribute(:elephant, :string)
  end
end
