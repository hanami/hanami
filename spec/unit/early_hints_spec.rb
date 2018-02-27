# frozen_string_literal: true

require "hanami/early_hints"

class EarlyHintsTest
  attr_reader :links

  def initialize
    @links = []
  end

  def call(links)
    @links.push(links.fetch("Link"))
  end
end

class BrokenEarlyHintsTest
  def call(*)
    raise NoMethodError.new("boom")
  end
end

RSpec.describe Hanami::EarlyHints do
  subject { described_class.new(app) }
  let(:app) { ->(*) { [200, {}, ["OK"]] } }

  let(:assets) do
    (1..23).each_with_object({}) do |i, memo|
      memo["/assets/stylesheet-#{i}.css"] = { as: "style", crossorigin: true }
    end
  end

  describe "#call" do
    before do
      Thread.current[:__hanami_assets] = nil
    end

    it "returns response from app" do
      response = subject.call({})
      expect(response).to eq([200, {}, ["OK"]])
    end

    context "with a server that supports Early Hints" do
      let(:early_hints) { EarlyHintsTest.new }
      let(:env) { Hash["rack.early_hints" => early_hints] }

      context "with pushed assets" do
        before do
          Thread.current[:__hanami_assets] = assets
        end

        it "sends Early Hints (103) responses" do
          subject.call(env)

          links = early_hints.links
          expect(links.count).to be(3) # (23 / Hanami::EarlyHints::BATCH_SIZE) + 1 == 3

          expect(links.first).to include(%(</assets/stylesheet-1.css>; rel=preload; as=style; crossorigin))
        end

        context "with broken implementation" do
          let(:early_hints) { BrokenEarlyHintsTest.new }

          it "raises original error" do
            expect do
              subject.call(env)
            end.to raise_error(NoMethodError, "boom")
          end
        end
      end

      context "without pushed assets" do
        it "doesn't send Early Hints (103) responses" do
          subject.call(env)
          expect(early_hints.links).to be_empty
        end
      end
    end

    context "with a server that doesn't support Early Hints" do
      let(:env) { Hash[] }

      context "with pushed assets" do
        before do
          Thread.current[:__hanami_assets] = assets
        end

        it "raises informative error" do
          expect do
            subject.call(env)
          end.to raise_error(Hanami::EarlyHints::NotSupportedByServerError, "Current Ruby server doesn't support Early Hints.\nPlease make sure to use a web server with Early Hints enabled (only Puma for now).")
        end
      end

      context "without pushed assets" do
        it "doesn't send Early Hints (103) responses" do
          response = subject.call(env)
          expect(response).to eq([200, {}, ["OK"]])
        end
      end
    end
  end
end
