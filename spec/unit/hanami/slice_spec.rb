require "hanami/slice"

RSpec.describe Hanami::Slice, :application_integration do
  subject(:slice) { Test::Slice = Class.new(described_class) }

  before do
    # FIXME: It's a problem that this doesn't work
    # Test::Application = Class.new(Hanami::Application)

    module Test
      class Application < Hanami::Application
      end
    end

    Test::Application.prepare
  end

  describe ".prepare_container" do
    it "allows the user to configure the container after defaults settings have been applied" do
      slice = Test::Slice = Class.new(described_class)
      slice.prepare
      expect(slice.container.config.name).to eq :test

      slice = Test::Slice = Class.new(described_class)
      slice.prepare_container do |container|
        container.config.name = :my_slice
      end
      slice.prepare
      expect(slice.container.config.name).to eq :my_slice
    end
  end
end
