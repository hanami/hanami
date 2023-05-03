# frozen_string_literal: true

require "dry/inflector"

RSpec.describe Hanami::Config, "#render_errors" do
  let(:config) { described_class.new(app_name: app_name, env: env) }
  let(:app_name) { Hanami::SliceName.new(double(name: "MyApp::App"), inflector: Dry::Inflector.new) }
  let(:env) { :development }

  subject(:render_errors) { config.render_errors }

  it "is false by default" do
    is_expected.to be false
  end

  context "test mode" do
    let(:env) { :test }
    it { is_expected.to be false }
  end

  context "production mode" do
    let(:env) { :production }
    it { is_expected.to be true }
  end
end
