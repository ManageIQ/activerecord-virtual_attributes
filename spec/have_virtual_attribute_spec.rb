describe "have_virtual_attribute" do
  it "detects virtual attribute" do
    expect(Author).to have_virtual_column(:nick_or_name)
  end

  it "understands non virtual attributes" do
    expect(Author).not_to have_virtual_column(:name)
    expect(Author).not_to have_virtual_column(:elephant)
  end
end
