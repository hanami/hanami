require "hanami/slice"

RSpec.describe Hanami::Slice, :app_integration do
  before do
    module TestApp
      class App < Hanami::App
      end
    end
  end

  describe ".app" do
    subject(:slice) { Hanami.app.register_slice(:main) }

    it "returns the top-level Hanami App slice" do
      expect(slice.app).to eq Hanami.app
    end
  end

  describe ".app?" do
    it "returns true if the slice is Hanami.app" do
      subject = Hanami.app
      expect(subject.app?).to eq true
    end

    it "returns false if the slice is not Hanami.app" do
      subject = Hanami.app.register_slice(:main)
      expect(subject.app?).to eq false
    end
  end

  describe ".environment" do
    subject(:slice) { Hanami.app.register_slice(:main) }

    before do
      allow(slice.config).to receive(:env) { :development }
    end

    it "evaluates the block with the env matches the Hanami.env" do
      expect {
        slice.environment(:development) do
          config.logger.level = :info
        end
      }
        .to change { slice.config.logger.level }
        .to :info
    end

    it "yields the slice to the block" do
      captured_slice = nil
      slice.environment(:development) { |slice| captured_slice = slice }
      expect(captured_slice).to be slice
    end

    it "does not evaluate the block with the env does not match the Hanami.env" do
      expect {
        slice.environment(:test) do
          config.logger.level = :info
        end
      }.not_to(change { slice.config.logger.level })
    end
  end

  describe ".prepare" do
    it "raises an error if the slice class is anonymous" do
      expect { Class.new(described_class).prepare }
        .to raise_error Hanami::SliceLoadError, /Slice must have a class name/
    end
  end
end
