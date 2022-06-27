require "hanami/configuration"

RSpec.describe Hanami::Configuration do
  let(:config) { described_class.new(application_name: application_name, env: env) }
  let(:application_name) { "MyApp::Application" }
  let(:env) { :development }

  describe "environment-specific configuration" do
    before do
      config.logger.level = :debug__set_without_env
    end

    before do
      config.environment :production do |c|
        c.logger.level = :info__set_for_production_env
      end
    end

    context "settings configured for current env" do
      let(:env) { :production }

      it "applies the settings" do
        expect(config.logger.level).to eq :info__set_for_production_env
      end

      it "leaves the settings in place when finalizing" do
        expect { config.finalize! }.not_to(change { config.logger.level })
      end
    end

    context "settings configured for a different env" do
      let(:env) { :development }

      it "does not apply the settings" do
        expect(config.logger.level).to eq :debug__set_without_env
      end

      it "does not apply the settings when finalizing" do
        expect { config.finalize! }.not_to(change { config.logger.level })
      end
    end
  end
end
