RSpec.describe "match_query_limit_of" do
  it "detects correct query count" do
    expect { Author.all.load }.to match_query_limit_of(1)
  end

  it "detects query count failure" do
    expect do
      expect { Author.all.load }.to match_query_limit_of(0)
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /Expected 0 queries, got 1/i)
  end

  it "detects a negative count test" do
    expect { Author.all.load }.not_to match_query_limit_of(0)
  end

  it "detects failure with a negative count test" do
    expect do
      expect { Author.all.load }.not_to match_query_limit_of(1)
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /Expect not to execute 1 queries/i)
  end
end
