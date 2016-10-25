RSpec.describe Hanami::Application do
  subject { UnitTesting::Application }

  describe ".configure" do
    before do
      subject.instance_variable_set(:@configurations, Hanami::EnvironmentApplicationConfigurations.new)
      subject.configure do
        root __dir__
      end
    end

    let(:configuration) do
      Hanami::ApplicationConfiguration.new(UnitTesting, subject.configurations, "/")
    end

    let(:environment) do
      Hanami::Environment.new.environment
    end

    context "without environment" do
      it "setups general settings" do
        expect(configuration.root.to_s).to eq(__dir__)
      end
    end

    context "with environment" do
      before do
        r = setting
        subject.configure(environment) do
          root r
        end
      end

      let(:setting) { [__dir__, "..", "..", "..", "tmp"].join(File::SEPARATOR) }

      it "setups per env settings" do
        expect(configuration.root.to_s).to eq(File.expand_path(setting))
      end

      it "allows to setup multiple times per env settings" do
        r = [__dir__, "..", "..", "support"].join(File::SEPARATOR)
        subject.configure(environment) do
          root r
        end

        expect(configuration.root.to_s).to eq(File.expand_path(r))
      end
    end
  end
end
