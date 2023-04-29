# frozen_string_literal: true

require "hanami/config"
require "saharspec/matchers/dont"

RSpec.describe Hanami::Config, "#views" do
  let(:config) { described_class.new(app_name: app_name, env: :development) }
  let(:app_name) { "MyApp::app" }

  subject(:views) { config.views }

  context "hanami-view is bundled" do
    it "exposes Hanami::Views's app config" do
      is_expected.to be_an_instance_of(Hanami::Config::Views)

      is_expected.to respond_to(:finalize!)
      is_expected.to respond_to(:layouts_dir)
      is_expected.to respond_to(:layouts_dir=)
    end

    it "includes base view config" do
      expect(views).to respond_to(:paths)
      expect(views).to respond_to(:paths=)
    end

    it "does not include the inflector setting" do
      expect(views).not_to respond_to(:inflector)
      expect(views).not_to respond_to(:inflector=)
    end

    it "preserves default values from the base view config" do
      expect(views.layouts_dir).to eq Hanami::View.config.layouts_dir
    end

    it "allows settings to be configured independently of the base view config" do
      expect { views.layouts_dir = "custom_layouts" }
        .to change { views.layouts_dir }.to("custom_layouts")
        .and(dont.change { Hanami::View.config.layouts_dir })
    end

    describe "specialised default values" do
      describe "layout" do
        it 'is "app"' do
          expect(views.layout).to eq "app"
        end
      end
    end

    describe "finalized config" do
      before do
        views.finalize!
      end

      it "is frozen" do
        expect(views).to be_frozen
      end

      it "does not allow changes to base view settings" do
        expect { views.paths = [] }.to raise_error(Dry::Configurable::FrozenConfigError)
      end
    end
  end

  context "hanami-view is not bundled" do
    before do
      allow(Hanami).to receive(:bundled?).and_call_original
      expect(Hanami).to receive(:bundled?).with("hanami-view").and_return(false)
    end

    it "does not expose any settings" do
      is_expected.to be_an_instance_of(Hanami::Config::NullConfig)
      is_expected.not_to respond_to(:layouts_dir)
      is_expected.not_to respond_to(:layouts_dir=)
    end

    it "can be finalized" do
      is_expected.to respond_to(:finalize!)
    end
  end
end
