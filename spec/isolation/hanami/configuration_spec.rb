RSpec.describe "Hanami.configuration" do
  it "raises error when try to access configuration, but not configured yet" do
    expect { Hanami.configuration }.to raise_error(RuntimeError, "Hanami not configured")
  end
end
