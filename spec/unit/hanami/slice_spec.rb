# frozen_string_literal: true

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

  describe ".prepare_container" do
    let(:app_modules) { %i[TestApp Slice1 Slice2] }

    it "allows the user to configure the container after defaults settings have been applied" do
      slice = Hanami.app.register_slice(:slice1).prepare
      expect(slice.container.config.name).to eq :slice1

      slice = Hanami.app.register_slice(:slice2) {
        prepare_container do |container|
          container.config.name = :my_slice
        end
      }.prepare
      expect(slice.container.config.name).to eq :my_slice
    end
  end
end
