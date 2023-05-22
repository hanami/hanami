require "hanami/config/actions"

RSpec.describe Hanami::Config::Actions, "#csrf_protection" do
  let(:config) { described_class.new }
  subject(:value) { config.csrf_protection }

  context "non-finalized config" do
    it "returns a default of nil" do
      is_expected.to be_nil
    end

    it "can be explicitly enabled" do
      config.csrf_protection = true
      is_expected.to be true
    end

    it "can be explicitly disabled" do
      config.csrf_protection = false
      is_expected.to be false
    end
  end

  context "finalized config" do
    context "sessions enabled" do
      before do
        config.sessions = :cookie, {secret: "abc"}
        config.finalize!
      end

      it "is true" do
        is_expected.to be true
      end

      context "explicitly disabled" do
        before do
          config.csrf_protection = false
        end

        it "is false" do
          is_expected.to be false
        end
      end
    end

    context "sessions not enabled" do
      before do
        config.finalize!
      end

      it "is true" do
        is_expected.to be false
      end
    end
  end
end
