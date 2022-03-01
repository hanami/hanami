require "hanami/configuration"

RSpec.describe Hanami::Configuration do
  let(:config) { described_class.new(application_name: application_name, env: env) }
  let(:application_name) { "MyApp::Application" }
  let(:env) { :development }

  describe "environment-specific configuration" do
    before do
      config.settings_path = "config/default_settings"
    end

    before do
      config.environment :production do |c|
        c.settings_path = "config/production_settings"
      end
    end

    context "settings configured for current env" do
      let(:env) { :production }

      it "applies the settings" do
        expect(config.settings_path).to eq "config/production_settings"
      end

      it "leaves the settings in place when finalizing" do
        expect { config.finalize! }.not_to change { config.settings_path }
      end
    end

    context "settings configured for a different env" do
      let(:env) { :development }

      it "does not apply the settings" do
        expect(config.settings_path).to eq "config/default_settings"
      end

      it "does not apply the settings when finalizing" do
        expect { config.finalize! }.not_to change { config.settings_path }
      end
    end
  end
end
