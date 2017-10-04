RSpec.describe "Hanami::VERSION" do
  it "returns current version" do
    expect(Hanami::VERSION).to eq("1.1.0.beta3")
  end
end
