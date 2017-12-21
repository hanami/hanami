RSpec.describe "Hanami.plugin" do
  it "raises error when try to confiure plugin before Hanami project" do
    expect { Hanami.plugin{} }.to raise_error(RuntimeError, "Hanami not configured")
  end
end
