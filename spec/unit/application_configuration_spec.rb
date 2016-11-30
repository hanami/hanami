RSpec.describe Hanami::ApplicationConfiguration do
  before do
    env['HANAMI_ENV']  = hanami_env
    env['HANAMI_PORT'] = hanami_port unless hanami_port.nil?
  end

  subject { described_class.new(namespace, configurations, path_prefix, env: environment) }

  let(:namespace)      { ApplicationConfigurationTesting }
  let(:configurations) { Hanami::EnvironmentApplicationConfigurations.new }
  let(:path_prefix)    { '/' }

  let(:environment)    { Hanami::Environment.new(env: env) }
  let(:env)            { Hash[] }

  let(:hanami_env)  { 'development' }
  let(:hanami_port) { nil }

  describe "#port" do
    context "when not configured" do
      it "returns the default value" do
        expect(subject.port).to eq(2300)
      end

      context "and force_ssl is active" do
        before do
          configurations.add(nil) do
            force_ssl true
          end
        end

        it "returns the default SSL port" do
          expect(subject.port).to eq(443)
        end
      end

      context "and HANAMI_PORT env var is set" do
        let(:hanami_port) { "8080" }

        it "returns the value from the env var" do
          expect(subject.port).to eq(8080)
        end

        context "and force_ssl is active" do
          before do
            configurations.add(nil) do
              force_ssl true
            end
          end

          it "returns the value from the env var" do
            expect(subject.port).to eq(8080)
          end
        end
      end
    end

    context "when already configured" do
      context "in the general configuration" do
        before do
          configurations.add(nil) do
            port 4600
          end
        end

        it "returns the configured value" do
          expect(subject.port).to eq(4600)
        end

        context "and overwritten by current environment configuration" do
          before do
            configurations.add(hanami_env) do
              port 8200
            end
          end

          it "returns the current environment value" do
            expect(subject.port).to eq(8200)
          end
        end

        context "and forced by env var" do
          let(:hanami_port) { 4321 }

          xit "returns the one from the env var" do
            expect(subject.port).to eq(4321)
          end
        end
      end

      context "only in the current environment configuration" do
        before do
          configurations.add(nil) do
            port 7200
          end
        end

        it "returns the configured value" do
          expect(subject.port).to eq(7200)
        end
      end

      context "and force_ssl is active" do
        before do
          configurations.add(nil) do
            port      4433
            force_ssl true
          end
        end

        it "returns the default SSL port" do
          expect(subject.port).to eq(4433)
        end
      end
    end
  end
end
