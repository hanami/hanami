# frozen_string_literal: true

require "hanami/configuration"
require "hanami/configuration/views"
require "saharspec/matchers/dont"

RSpec.describe Hanami::Configuration, "#views" do
  let(:configuration) { described_class.new(app_name: app_name, env: :development) }
  let(:app_name) { "MyApp::app" }

  subject(:views) { configuration.views }

  context "Hanami::View available" do
    it "exposes Hanami::Views's app configuration" do
      is_expected.to be_an_instance_of(Hanami::Configuration::Views)

      is_expected.to respond_to(:finalize!)
      is_expected.to respond_to(:layouts_dir)
      is_expected.to respond_to(:layouts_dir=)
    end

    it "includes base view configuration" do
      expect(views).to respond_to(:paths)
      expect(views).to respond_to(:paths=)
    end

    it "does not include the inflector setting" do
      expect(views).not_to respond_to(:inflector)
      expect(views).not_to respond_to(:inflector=)
    end

    describe "#settings" do
      it "includes locally defined settings" do
        expect(views.settings).to include :parts_path
      end

      it "includes all view settings apart from inflector" do
        expect(views.settings).to include (Hanami::View.settings - [:inflector])
      end
    end

    it "preserves default values from the base view configuration" do
      expect(views.layouts_dir).to eq Hanami::View.config.layouts_dir
    end

    it "allows settings to be configured independently of the base view configuration" do
      expect { views.layouts_dir = "custom_layouts" }
        .to change { views.layouts_dir }.to("custom_layouts")
        .and(dont.change { Hanami::View.config.layouts_dir })
    end

    describe "specialised default values" do
      describe "paths" do
        it 'is ["templates"]' do
          expect(views.paths).to match [
            an_object_satisfying { |path| path.dir.to_s == "templates" }
          ]
        end
      end

      describe "template_inference_base" do
        it 'is "views"' do
          expect(views.template_inference_base).to eq "views"
        end
      end

      describe "layout" do
        it 'is "app"' do
          expect(views.layout).to eq "app"
        end
      end
    end

    describe "finalized configuration" do
      before do
        views.finalize!
      end

      it "is frozen" do
        expect(views).to be_frozen
      end

      it "does not allow changes to locally defined settings" do
        expect { views.parts_path = "parts" }.to raise_error(Dry::Configurable::FrozenConfig)
      end

      it "does not allow changes to base view settings" do
        expect { views.paths = [] }.to raise_error(Dry::Configurable::FrozenConfig)
      end
    end
  end

  context "Hanami::View not available" do
    before do
      load_error = LoadError.new.tap do |error|
        error.instance_variable_set :@path, "hanami/view"
      end

      allow_any_instance_of(described_class)
        .to receive(:require)
        .with(anything)
        .and_call_original

      allow_any_instance_of(described_class)
        .to receive(:require)
        .with("hanami/view")
        .and_raise load_error
    end

    it "raises an error" do
      expect { subject }.to raise_error(described_class::ComponentNotAvailable, "`hanami/view` is not available")
    end
  end
end
