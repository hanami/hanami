# frozen_string_literal: true

RSpec.describe "Hanami::VERSION" do
  it "returns current version" do
    expect(Hanami::VERSION).to eq("2.3.0.beta1")
  end
end
