require "hanami/slice"

RSpec.describe Hanami::Slice, :app_integration do
  before do
    module TestApp
      class App < Hanami::App
      end
    end
  end

  describe ".environemnt" do
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
