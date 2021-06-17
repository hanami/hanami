# frozen_string_literal: true

require "hanami/application/settings/struct"

RSpec.describe Hanami::Application::Settings::Struct do
  subject(:struct) { described_class[settings.keys].new(settings) }

  let(:settings) {
    {
      database_url: "postgres://localhost/test_app_development",
      redis_url: "redis://localhost:6379",
    }
  }

  describe "accessing settings" do
    it "makes known settings available as methods" do
      expect(struct.database_url).to eq "postgres://localhost/test_app_development"
      expect(struct.redis_url).to eq "redis://localhost:6379"
    end

    it "raises NoMethodError for unknown settings" do
      expect { struct.unknown_setting }.to raise_error NoMethodError
    end

    describe "reserved names" do
      let(:settings) {
        {
          object_id: "object_id setting",
        }
      }

      specify "are available via #[] only" do
        expect(struct.object_id).to be_an Integer
        expect(struct[:object_id]).to eq "object_id setting"
      end
    end
  end

  describe "#[]" do
    it "returns known settings" do
      expect(struct[:database_url]).to eq "postgres://localhost/test_app_development"
    end

    it "raises ArgumentError for unknown settings" do
      expect { struct[:unknown] }.to raise_error ArgumentError, /Unknown setting/
    end
  end

  describe "#to_h" do
    it "returns a hash of all settings" do
      expect(struct.to_h).to eq settings
    end
  end
end
