describe "have_virtual_attribute" do
  it "detects virtual attribute" do
    expect(Author).to have_virtual_attribute(:nick_or_name)
  end

  it "understands non virtual attributes" do
    expect(Author).not_to have_virtual_attribute(:name)
    expect(Author).not_to have_virtual_attribute(:elephant)
  end
end
