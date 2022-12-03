# frozen_string_literal: true

require "hanami/port"

RSpec.describe Hanami::Port do
  context "Hanami::Port::DEFAULT" do
    it "returns default value" do
      expect(Hanami::Port::DEFAULT).to eq(2300)
    end
  end

  context "Hanami::Port::ENV_VAR" do
    it "returns default value" do
      expect(Hanami::Port::ENV_VAR).to eq("HANAMI_PORT")
    end
  end

  context ".call" do
    let(:value) { nil }
    let(:env) { nil }

    it "is aliased as .[]" do
      expect(described_class[value, env]).to be(2300)
    end

    context "when ENV var is nil" do
      context "and value is nil" do
        it "returns default value" do
          expect(described_class.call(value, env)).to be(2300)
        end
      end

      context "and value is not nil" do
        let(:value) { 18_000 }

        it "returns given value" do
          expect(described_class.call(value, env)).to be(value)
        end

        context "and value is default" do
          let(:value) { 2300 }

          it "returns given value" do
            expect(described_class.call(value, env)).to be(value)
          end
        end
      end
    end

    context "when ENV var not nil" do
      let(:env) { 9000 }

      context "and value is nil" do
        it "returns env value" do
          expect(described_class.call(value, env)).to be(env)
        end
      end

      context "and value is not nil" do
        let(:value) { 18_000 }

        it "returns given value" do
          expect(described_class.call(value, env)).to be(value)
        end

        context "and value is default" do
          let(:value) { 2300 }

          it "returns env value" do
            expect(described_class.call(value, env)).to be(env)
          end
        end
      end
    end
  end

  context ".call!" do
    before { ENV.delete("HANAMI_PORT") }
    let(:value) { 2300 }

    context "when given value is default" do
      it "doesn't set env var" do
        described_class.call!(value)

        expect(ENV.key?("HANAMI_PORT")).to be(false)
      end
    end

    context "when given value isn't default" do
      let(:value) { 9000 }

      it "set env var" do
        described_class.call!(value)

        expect(ENV.fetch("HANAMI_PORT")).to eq(value.to_s)
      end
    end
  end

  context ".default?" do
    context "when given value is default" do
      let(:value) { 2300 }

      it "returns true" do
        expect(described_class.default?(value)).to be(true)
      end
    end

    context "when given value isn't default" do
      let(:value) { 9000 }

      it "returns false" do
        expect(described_class.default?(value)).to be(false)
      end
    end
  end
end
