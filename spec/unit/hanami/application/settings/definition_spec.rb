# frozen_string_literal: true

require "hanami/application/settings/definition"

RSpec.describe Hanami::Application::Settings::Definition do
  subject(:definition) { described_class.new(&block) }

  let(:block) { nil }

  describe ".new" do
    context "without block" do
      it "creates empty settings" do
        expect(definition.settings).to eq []
      end
    end

    context "with block" do
      let(:block) {
        proc do
          setting :database_url
          setting :redis_url, "args..."
        end
      }

      it "evaluates the block and stores settings and their arguments" do
        expect(definition.settings).to eq [
          [:database_url, []],
          [:redis_url, ["args..."]],
        ]
      end
    end
  end

  describe "#setting" do
    it "adds a setting and its arguments" do
      expect {
        definition.setting :redis_url, "args..."
      }
        .to change {
          definition.settings
        }
        .from([])
        .to([[:redis_url, ["args..."]]])
    end
  end
end
