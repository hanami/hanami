# frozen_string_literal: true

require "hanami/configuration/actions"

RSpec.describe Hanami::Configuration::Actions, "#default_response_format" do
  let(:configuration) { described_class.new }
  subject(:value) { configuration.default_response_format }

  it "returns the default" do
    is_expected.to eq :html
  end

  it "can be set" do
    configuration.default_response_format = :json
    is_expected.to eq :json
  end
end
