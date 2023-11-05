# frozen_string_literal: true

require "dry/inflector"

RSpec.describe Hanami::Config, "#render_detailed_errors" do
  let(:config) { described_class.new(app_name: app_name, env: env) }
  let(:app_name) { Hanami::SliceName.new(double(name: "MyApp::App"), inflector: Dry::Inflector.new) }

  subject(:render_detailed_errors) { config.render_detailed_errors }

  context "development mode" do
    let(:env) { :development }
    it { is_expected.to be true }
  end

  context "test mode" do
    let(:env) { :test }
    it { is_expected.to be false }
  end

  context "production mode" do
    let(:env) { :production }
    it { is_expected.to be false }
  end
end
