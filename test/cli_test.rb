require 'test_helper'
require 'hanami/cli'
require 'hanami/commands/generate/migration'
require 'hanami/commands/generate/model'
require 'hanami/commands/generate/action'
require 'hanami/commands/generate/app'
require 'hanami/commands/new/container'
require 'hanami/commands/new/app'

describe Hanami::Cli do
  let(:mock_without_method) { Minitest::Mock.new }

  describe 'new' do
    let(:default_options) { {
      'database' => 'filesystem',
      'architecture' => 'container',
      'application_name' => 'web',
      'application_base_url' => '/',
      'template' => 'erb',
      'test' => 'minitest',
      'hanami_head' => false}
    }
    describe 'container' do
      it 'calls the generator with application name and defaults' do
        ARGV.replace(%w{new fancy-app})
        assert_cli_calls_command(Hanami::Commands::New::Container, default_options, 'fancy-app')
      end

      it 'does not call the generator if application name is missing' do
        ARGV.replace(%w{new})
        Hanami::Commands::New::Container.stub(:new, mock_without_method) do
          capture_io { Hanami::Cli.start }
        end
      end

      it 'passes the supported options to the generator' do
        options = default_options.merge(
          'database' => 'memory',
          'application_name' => 'admin',
          'application_base_url' => '/web-admin',
          'test' => 'rspec',
          'hanami_head' => true,
          'template' => 'slim'
        )
        ARGV.replace(%w{new fancy-app --database=memory --application_name=admin --application_base_url=/web-admin --test=rspec --hanami_head=true --template=slim})
        assert_cli_calls_command(Hanami::Commands::New::Container, options, 'fancy-app')
      end

    end

    describe 'app' do
      let(:options) { default_options.merge('architecture' => 'app')}
      it 'calls the generator with application name and defaults' do
        ARGV.replace(%w{new fancy-app --architecture=app})
        assert_cli_calls_command(Hanami::Commands::New::App, options, 'fancy-app')
      end

      it 'does not call the generator if application name is missing' do
        ARGV.replace(%w{new --architecture=app})
        Hanami::Commands::New::Container.stub(:new, mock_without_method) do
          capture_io { Hanami::Cli.start }
        end
      end

      it 'passes the supported options to the generator' do
        options = default_options.merge(
          'architecture' => 'app',
          'database' => 'memory',
          'application_base_url' => '/web-admin',
          'test' => 'rspec',
          'hanami_head' => true
        )
        ARGV.replace(%w{new fancy-app --database=memory --application_base_url=/web-admin --test=rspec --hanami_head=true --architecture=app})
        assert_cli_calls_command(Hanami::Commands::New::App, options, 'fancy-app')
      end
    end
  end

  describe 'generate' do
    describe 'action' do
      let(:default_options) { {'skip_view' => false} }

      it 'calls the generator with application and controller/action name' do
        ARGV.replace(%w{generate action app controller#action})

        assert_cli_calls_command(Hanami::Commands::Generate::Action, default_options, 'app', 'controller#action')
      end

      it 'passes the supported options' do
        ARGV.replace(%w{generate action app controller#action --method=put --url=/foo --test=rspec --template=haml})
        options = default_options.merge('method' => 'put', 'url' => '/foo', 'test' => 'rspec', 'template' => 'haml')

        assert_cli_calls_command(Hanami::Commands::Generate::Action, options, 'app', 'controller#action')
      end

      describe 'for container application' do
        before { setup_container_app }

        it 'raises an error when app and controller name are missing' do
          ARGV.replace(%w{generate action})

          Hanami::Commands::Generate::Action.stub(:new, mock_without_method) do
            _, err = capture_io { Hanami::Cli.start }
            assert_match 'ERROR', err
          end
        end

        it 'raises an error when controller name is missing' do
          ARGV.replace(%w{generate action foo})

          Hanami::Commands::Generate::Action.stub(:new, mock_without_method) do
            _, err = capture_io { Hanami::Cli.start }
            assert_match 'ERROR', err
          end
        end

        it 'raises an error when app name is missing' do
          ARGV.replace(%w{generate action controller#action})

          Hanami::Commands::Generate::Action.stub(:new, mock_without_method) do
            _, err = capture_io { Hanami::Cli.start }
            assert_match 'ERROR', err
          end
        end
      end

      describe 'for app application' do
        before do
          setup_app_app
          mock_without_method.expect(:start, nil)
        end

        it 'it generates action when controller name is present' do
          ARGV.replace(%w{generate action controller#action})

          Hanami::Commands::Generate::Action.stub(:new, mock_without_method) do
            _, err = capture_io { Hanami::Cli.start }
            refute_match 'ERROR', err
          end
        end

        it 'raises error when controller name is missing' do
          ARGV.replace(%w{generate action})

          Hanami::Commands::Generate::Action.stub(:new, mock_without_method) do
            _, err = capture_io { Hanami::Cli.start }
            assert_match 'ERROR', err
          end
        end
      end
    end

    describe 'migration' do
      it 'calls the generator with migration name' do
        ARGV.replace(%w{generate migration add_thing})

        assert_cli_calls_command(Hanami::Commands::Generate::Migration, {}, 'add_thing')
      end

      it 'does not call the generator when name is missing' do
        ARGV.replace(%w{generate migration})
        Hanami::Commands::Generate::Migration.stub(:new, mock_without_method) do
          capture_io { Hanami::Cli.start }
        end
      end
    end

    describe 'model' do
      it 'calls the generator with model name' do
        ARGV.replace(%w{generate model car})

        assert_cli_calls_command(Hanami::Commands::Generate::Model, {}, 'car')
      end

      it 'does not call the generator when name is missing' do
        ARGV.replace(%w{generate model})
        Hanami::Commands::Generate::Model.stub(:new, mock_without_method) do
          capture_io { Hanami::Cli.start }
        end
      end
    end

    describe 'app' do
      it 'calls the generator with app name' do
        ARGV.replace(%w{generate app admin})
        assert_cli_calls_command(Hanami::Commands::Generate::App, {}, 'admin')
      end


      it 'passes the supported options' do
        ARGV.replace(%w{generate app admin --application_base_url=/backend})
        options = {'application_base_url' => '/backend'}

        assert_cli_calls_command(Hanami::Commands::Generate::App, options, 'admin')
      end
    end
  end

  describe 'version' do
    describe 'when `version` command' do
      it 'prints Hanami version' do
        assert_output("v#{Hanami::VERSION}\n") do
          ARGV.replace(%w{version})
          Hanami::Cli.start
        end
      end
    end

    describe 'when passing --version to hanami command, with no subcommand' do
      it 'prints Hanami version' do
        assert_output("v#{Hanami::VERSION}\n") do
          ARGV.replace(%w{--version})
          Hanami::Cli.start
        end
      end
    end

    describe 'when passing -v to hanami command, with no subcommand' do
      it 'prints Hanami version' do
        assert_output("v#{Hanami::VERSION}\n") do
          ARGV.replace(%w{-v})
          Hanami::Cli.start
        end
      end
    end
  end

  def setup_container_app
    File.open('.hanamirc', 'w') { |file| file << "architecture=container"}
  end

  def setup_app_app
    File.open('.hanamirc', 'w') { |file| file << "architecture=app"}
  end

  # Helper method to make sure that the Command class is called with good arguments.
  def assert_cli_calls_command(command_class, *expected_arguments)
    instance_mock = Minitest::Mock.new
    instance_mock.expect(:start, nil)

    constructor_args_verifier = lambda do |*actual_arguments|
      assert_equal expected_arguments.size, actual_arguments.size
      expected_arguments.each_with_index do |expected_argument, index|
        actual_argument = actual_arguments[index]
        message = "Expected argument #{index} to #{command_class.name} to be '#{expected_argument.inspect}' but was '#{actual_argument.inspect}'"
        assert_equal expected_argument, actual_argument, message
      end
      instance_mock
    end

    command_class.stub(:new, constructor_args_verifier) do
      capture_io { Hanami::Cli.start }
    end

    instance_mock.verify
  end

end
