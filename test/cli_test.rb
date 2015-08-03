require 'test_helper'
require 'lotus/cli'
require 'lotus/commands/generate/migration'
require 'lotus/commands/generate/model'
require 'lotus/commands/generate/action'
require 'lotus/commands/generate/app'
require 'lotus/commands/new/container'
require 'lotus/commands/new/app'

describe Lotus::Cli do
  let(:mock_without_method) { Minitest::Mock.new }

  describe 'new' do
    let(:default_options) { {
      'database' => 'filesystem',
      'architecture' => 'container',
      'application_name' => 'web',
      'application_base_url' => '/',
      'test' => 'minitest',
      'lotus_head' => false}
    }
    describe 'container' do
      it 'calls the generator with application name and defaults' do
        ARGV.replace(%w{new fancy-app})
        assert_cli_calls_command(Lotus::Commands::New::Container, default_options, 'fancy-app')
      end

      it 'does not call the generator if application name is missing' do
        ARGV.replace(%w{new})
        Lotus::Commands::New::Container.stub(:new, mock_without_method) do
          capture_io { Lotus::Cli.start }
        end
      end

      it 'passes the supported options to the generator' do
        options = default_options.merge(
          'database' => 'memory',
          'application_name' => 'admin',
          'application_base_url' => '/web-admin',
          'test' => 'rspec',
          'lotus_head' => true
        )
        ARGV.replace(%w{new fancy-app --database=memory --application_name=admin --application_base_url=/web-admin --test=rspec --lotus_head=true})
        assert_cli_calls_command(Lotus::Commands::New::Container, options, 'fancy-app')
      end

    end

    describe 'app' do
      let(:options) { default_options.merge('architecture' => 'app')}
      it 'calls the generator with application name and defaults' do
        ARGV.replace(%w{new fancy-app --architecture=app})
        assert_cli_calls_command(Lotus::Commands::New::App, options, 'fancy-app')
      end

      it 'does not call the generator if application name is missing' do
        ARGV.replace(%w{new --architecture=app})
        Lotus::Commands::New::Container.stub(:new, mock_without_method) do
          capture_io { Lotus::Cli.start }
        end
      end

      it 'passes the supported options to the generator' do
        options = default_options.merge(
          'architecture' => 'app',
          'database' => 'memory',
          'application_base_url' => '/web-admin',
          'test' => 'rspec',
          'lotus_head' => true
        )
        ARGV.replace(%w{new fancy-app --database=memory --application_base_url=/web-admin --test=rspec --lotus_head=true --architecture=app})
        assert_cli_calls_command(Lotus::Commands::New::App, options, 'fancy-app')
      end
    end
  end

  describe 'generate' do
    describe 'action' do
      let(:default_options) { {'method' => 'GET', 'skip_view' => false} }

      it 'calls the generator with application and controller/action name' do
        ARGV.replace(%w{generate action app controller#action})

        assert_cli_calls_command(Lotus::Commands::Generate::Action, default_options, 'app', 'controller#action')
      end

      it 'passes the supported options' do
        ARGV.replace(%w{generate action app controller#action --method=put --url=/foo --test=rspec --template=haml})
        options = default_options.merge('method' => 'put', 'url' => '/foo', 'test' => 'rspec', 'template' => 'haml')

        assert_cli_calls_command(Lotus::Commands::Generate::Action, options, 'app', 'controller#action')
      end

      it 'does not call the generator when app or controller name is missing' do
        ARGV.replace(%w{generate action})
        Lotus::Commands::Generate::Action.stub(:new, mock_without_method) do
          capture_io { Lotus::Cli.start }
        end

        ARGV.replace(%w{generate action foo})
        Lotus::Commands::Generate::Action.stub(:new, mock_without_method) do
          capture_io { Lotus::Cli.start }
        end
      end
    end

    describe 'migration' do
      it 'calls the generator with migration name' do
        ARGV.replace(%w{generate migration add_thing})

        assert_cli_calls_command(Lotus::Commands::Generate::Migration, {}, 'add_thing')
      end

      it 'does not call the generator when name is missing' do
        ARGV.replace(%w{generate migration})
        Lotus::Commands::Generate::Migration.stub(:new, mock_without_method) do
          capture_io { Lotus::Cli.start }
        end
      end
    end

    describe 'model' do
      it 'calls the generator with model name' do
        ARGV.replace(%w{generate model car})

        assert_cli_calls_command(Lotus::Commands::Generate::Model, {}, 'car')
      end

      it 'does not call the generator when name is missing' do
        ARGV.replace(%w{generate model})
        Lotus::Commands::Generate::Model.stub(:new, mock_without_method) do
          capture_io { Lotus::Cli.start }
        end
      end
    end

    describe 'app' do
      it 'calls the generator with app name' do
        ARGV.replace(%w{generate app admin})
        assert_cli_calls_command(Lotus::Commands::Generate::App, {}, 'admin')
      end


      it 'passes the supported options' do
        ARGV.replace(%w{generate app admin --application_base_url=/backend})
        options = {'application_base_url' => '/backend'}

        assert_cli_calls_command(Lotus::Commands::Generate::App, options, 'admin')
      end
    end
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
      capture_io { Lotus::Cli.start }
    end

    instance_mock.verify
  end

end
