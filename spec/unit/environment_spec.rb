RSpec.describe Hanami::Environment do
  let(:env) { Hash[] }

  let(:default_development_env) do
    Hash[
      'RACK_ENV'    => 'development',
      'HANAMI_ENV'  => 'development',
      'HANAMI_HOST' => 'localhost',
      'HANAMI_PORT' => '2300'
    ]
  end

  let(:default_test_env) do
    Hash[
      'RACK_ENV'    => 'test',
      'HANAMI_ENV'  => 'test',
      'HANAMI_HOST' => '0.0.0.0',
      'HANAMI_PORT' => '2300'
    ]
  end

  describe "#initialize" do
    context "global .env" do
      it "doesn't set env vars from .env" do
        with_directory('spec/support/fixtures') do
          described_class.new(env: env)

          expect(env['FOO']).to be_nil # see spec/support/fixtures/.env
        end
      end

      it "doesn't sets port" do
        with_directory('spec/support/fixtures') do
          subject = described_class.new(env: env)

          # returns default instead the value from spec/support/fixtures/.env
          expect(subject.port).to eq(2300)
        end
      end
    end

    context "per environment .env" do
      it "sets env vars from .env.development" do
        with_directory('spec/support/fixtures/dotenv') do
          described_class.new(env: env)

          expect(env['HANAMI_PORT']).to eq('42')

          expect(env['BAZ']).to eq('yes')
          expect(env['WAT']).to eq('true')
        end
      end

      it "sets port from .env.development" do
        with_directory('spec/support/fixtures/dotenv') do
          subject = described_class.new(env: env)

          expect(subject.port).to eq(42)
        end
      end

      context 'with same ENV variable set in ENV and .env.development' do
        let(:env) { {'WAT' => 'false'} }

        it 'sets manual set ENV vars over .env.development set' do
          with_directory('spec/support/fixtures/dotenv') do
            described_class.new(env: env)

            expect(env['HANAMI_PORT']).to eq('42')

            expect(env['BAZ']).to eq('yes')
            expect(env['WAT']).to eq('false')
          end
        end
      end
    end

    context "missing per environment .env" do
      it "doesn't alter env" do
        with_directory('spec/support/fixtures/nodotenv') do
          described_class.new(env: env)

          expect(env).to eq(default_development_env)
        end
      end
    end

    context "when the .env for the current environment is missing" do
      let(:env) { Hash['HANAMI_ENV' => 'test'] }

      it "doesn't set env vars" do
        with_directory('spec/support/fixtures/dotenv') do
          described_class.new(env: env)

          expect(env).to eq(default_test_env)
        end
      end
    end
  end # initialize

  describe "#environment" do
    context "when HANAMI_ENV isn't set" do
      it "returns 'development'" do
        subject = described_class.new(env: env)

        expect(subject.environment).to eq('development')
      end
    end

    context "when HANAMI_ENV is set" do
      let(:env) { Hash['HANAMI_ENV' => 'test'] }

      it "returns that value" do
        subject = described_class.new(env: env)

        expect(subject.environment).to eq('test')
      end
    end

    context "when RACK_ENV is set to 'production'" do
      let(:env) { Hash['RACK_ENV' => 'production'] }

      it "returns that value" do
        subject = described_class.new(env: env)

        expect(subject.environment).to eq('production')
      end
    end

    context "when RACK_ENV is set to 'deployment'" do
      let(:env) { Hash['RACK_ENV' => 'deployment'] }

      it "returns 'production'" do
        subject = described_class.new(env: env)

        expect(subject.environment).to eq('production')
      end
    end

    context "when both HANAMI_ENV and RACK_ENV are set" do
      let(:env) { Hash['HANAMI_ENV' => 'test', 'RACK_ENV' => 'production'] }

      it "gives precedence to HANAMI_ENV" do
        subject = described_class.new(env: env)

        expect(subject.environment).to eq('test')
      end
    end

    context "when env vars are changed from different process" do
      it "doesn't change value after initialization" do
        subject = described_class.new(env: env)

        expect(subject.environment).to eq('development')

        env['HANAMI_ENV'] = 'production'
        expect(subject.environment).to eq('development')
      end
    end
  end # environment

  describe "#environment?" do
    subject { described_class.new(env: env) }

    context "when matched" do
      let(:env) { Hash['HANAMI_ENV' => 'test'] }

      context "with single name" do
        it "returns true" do
          expect(subject.environment?(:test)).to  be(true)
          expect(subject.environment?('test')).to be(true)
        end
      end

      context "with multiple names" do
        it "returns true" do
          expect(subject.environment?(:development,  :test)).to  be(true)
          expect(subject.environment?('development', 'test')).to be(true)
        end
      end
    end

    context "when not matched" do
      let(:env) { Hash['HANAMI_ENV' => 'development'] }

      context "with single name" do
        it "returns false" do
          expect(subject.environment?(:test)).to  be(false)
          expect(subject.environment?('test')).to be(false)
        end
      end

      context "with multiple names" do
        it "returns false" do
          expect(subject.environment?(:test,  :production)).to  be(false)
          expect(subject.environment?('test', 'production')).to be(false)
        end
      end
    end
  end # environment?

  describe "#bundler_groups" do
    it "returns a set of groups for Bundler" do
      subject = described_class.new(env: env)

      expect(subject.bundler_groups).to eq([:default, subject.environment])
    end
  end # bundler_groups

  describe "#host" do
    context "when not specified" do
      context "and default env" do
        it "returns 'localhost'" do
          subject = described_class.new(env: env)

          expect(subject.host).to eq('localhost')
        end
      end

      context "and other env" do
        let(:env) { Hash['HANAMI_ENV' => 'test'] }

        it "returns '0.0.0.0'" do
          subject = described_class.new(env: env)

          expect(subject.host).to eq('0.0.0.0')
        end
      end
    end

    context "when specified while initializing" do
      it 'returns that value' do
        subject = described_class.new(env: env, host: host = 'hanamirb.test')

        expect(subject.host).to eq(host)
      end
    end

    context "when HANAMI_HOST is set" do
      let(:env)  { Hash['HANAMI_HOST' => host] }
      let(:host) { 'hanami.host' }

      it 'returns that value' do
        subject = described_class.new(env: env)

        expect(subject.host).to eq(host)
      end
    end

    context "when both the option and HANAMI_HOST are set" do
      let(:env) { Hash['HANAMI_HOST' => 'hanami.host'] }

      it 'returns that value' do
        subject = described_class.new(env: env, host: host = 'hanamirb.org')

        expect(subject.host).to eq(host)
      end
    end
  end # host

  describe "#port" do
    context "when not specified" do
      it "returns 2300" do
        subject = described_class.new(env: env)

        expect(subject.port).to eq(2300)
      end
    end

    context "when specified while initializing" do
      it 'returns that value' do
        subject = described_class.new(env: env, port: port = 9292)

        expect(subject.port).to eq(port)
      end
    end

    context "when HANAMI_PORT is set" do
      let(:env)  { Hash['HANAMI_PORT' => port] }
      let(:port) { 8080 }

      it 'returns that value' do
        subject = described_class.new(env: env)

        expect(subject.port).to eq(port)
      end
    end

    context "when both the option and HANAMI_PORT are set" do
      let(:env) { Hash['HANAMI_PORT' => 8081] }

      it 'returns that value' do
        subject = described_class.new(env: env, port: port = 9393)

        expect(subject.port).to eq(port)
      end
    end
  end # port

  describe "#project_name" do
    it "equals to given value" do
      subject = described_class.new(env: env, project: project = 'bookshelf')

      expect(subject.project_name).to eq(project)
    end
  end # project_name

  describe "#root" do
    it "equals to Dir.pwd" do
      subject = described_class.new(env: env)

      expect(subject.root).to eq(Pathname(Dir.pwd))
    end
  end # root

  describe "#rackup" do
    it "is 'config.ru' at root" do
      subject = described_class.new(env: env)

      expect(subject.rackup).to eq(subject.root.join('config.ru'))
    end
  end # rackup
end
