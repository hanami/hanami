require "hanami/slice"

RSpec.describe Hanami::Slice, :app_integration do
  before do
    module TestApp
      class App < Hanami::App
      end
    end
  end

  describe ".prepare" do
    it "raises an error if the slice class is anonymous" do
      expect { Class.new(described_class).prepare }
        .to raise_error Hanami::SliceLoadError, /Slice must have a class name/
    end
  end
end
