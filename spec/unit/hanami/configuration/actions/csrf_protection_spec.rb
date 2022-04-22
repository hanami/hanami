# frozen_string_literal: true

require "hanami/configuration/actions"

RSpec.describe Hanami::Configuration::Actions, "#csrf_protection" do
  let(:configuration) { described_class.new }
  subject(:value) { configuration.csrf_protection }

  context "non-finalized configuration" do
    it "returns a default of nil" do
      is_expected.to be_nil
    end

    it "can be explicitly enabled" do
      configuration.csrf_protection = true
      is_expected.to be true
    end

    it "can be explicitly disabled" do
      configuration.csrf_protection = false
      is_expected.to be false
    end
  end

  context "finalized configuration" do
    context "sessions enabled" do
      before do
        configuration.sessions = :cookie, {secret: "abc"}
        configuration.finalize!
      end

      it "is true" do
        is_expected.to be true
      end

      context "explicitly disabled" do
        before do
          configuration.csrf_protection = false
        end

        it "is false" do
          is_expected.to be false
        end
      end
    end

    context "sessions not enabled" do
      before do
        configuration.finalize!
      end

      it "is true" do
        is_expected.to be false
      end
    end
  end
end
