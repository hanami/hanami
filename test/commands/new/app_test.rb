require 'test_helper'
require 'hanami/commands/new/app'
require 'fileutils'

describe Hanami::Commands::New::App do
  describe 'with invalid arguments' do
    it 'requires application name' do
      with_temp_dir do |original_wd|
        exception = -> { Hanami::Commands::New::App.new({}, nil) }.must_raise ArgumentError
        exception.message.must_equal 'APPLICATION_NAME is required and must not contain /.'

        exception = -> { Hanami::Commands::New::App.new({}, '') }.must_raise ArgumentError
        exception.message.must_equal 'APPLICATION_NAME is required and must not contain /.'

        exception = -> { Hanami::Commands::New::App.new({}, '  ') }.must_raise ArgumentError
        exception.message.must_equal 'APPLICATION_NAME is required and must not contain /.'

        exception = -> { Hanami::Commands::New::App.new({}, 'foo/bar') }.must_raise ArgumentError
        exception.message.must_equal 'APPLICATION_NAME is required and must not contain /.'
      end
    end

    it 'validates test option' do
      with_temp_dir do |original_wd|
        exception = -> { Hanami::Commands::New::App.new({test: 'unknown'}, 'new_app') }.must_raise ArgumentError
        exception.message.must_equal "Unknown test framework 'unknown'. Please use one of 'rspec', 'minitest'"
      end
    end

    it 'validates database option' do
      with_temp_dir do |original_wd|
        exception = -> { Hanami::Commands::New::App.new({database: 'unknown'}, 'new_app') }.must_raise RuntimeError
        exception.message.must_equal '"unknown" is not a valid database type'
      end
    end

    it 'validates console option' do
      with_temp_dir do |original_wd|
        exception = -> { Hanami::Commands::New::App.new({console: 'unknown'}, 'app_name') }.must_raise ArgumentError
        exception.message.must_equal "Unknown console engine 'unknown'. Please use one of 'pry', 'irb', 'ripl'"
      end
    end

    it 'does not support application_name' do
      with_temp_dir do |original_wd|
        -> { Hanami::Commands::New::App.new({application_name: 'application_name'}, nil) }.must_raise ArgumentError
      end
    end
  end

  describe 'with valid arguments' do
    describe 'for console engine' do
      describe 'irb' do
        describe 'when no console engine is specified' do
          it 'creates files that fallback to irb engine' do
            with_temp_dir do |original_wd|
              command = Hanami::Commands::New::App.new({}, 'new_app')
              capture_io { command.start }

              assert_generated_app(original_wd, console_engine: 'irb')
            end
          end
        end

        it 'creates files' do
          with_temp_dir do |original_wd|
            command = Hanami::Commands::New::App.new({console: 'irb'}, 'new_app')
            capture_io { command.start }

            assert_generated_app(original_wd, console_engine: 'irb')
          end
        end
      end

      describe 'pry' do
        it 'creates files' do
          with_temp_dir do |original_wd|
            command = Hanami::Commands::New::App.new({console: 'pry'}, 'new_app')
            capture_io { command.start }

            assert_generated_app(original_wd, console_engine: 'pry')
          end
        end
      end

      describe 'ripl' do
        it 'creates files' do
          with_temp_dir do |original_wd|
            command = Hanami::Commands::New::App.new({console: 'ripl'}, 'new_app')
            capture_io { command.start }

            assert_generated_app(original_wd, console_engine: 'ripl')
          end
        end
      end
    end

    describe 'for test framework' do
      describe 'minitest' do
        it 'creates files' do
          with_temp_dir do |original_wd|
            command = Hanami::Commands::New::App.new({}, 'new_app')
            capture_io { command.start }

            assert_generated_app(original_wd, test_framework: 'minitest')
          end
        end
      end

      describe 'rspec' do
        it 'creates files' do
          with_temp_dir do |original_wd|
            command = Hanami::Commands::New::App.new({'test' => 'rspec'}, 'new_app')
            capture_io { command.start }

            assert_generated_app(original_wd, test_framework: 'rspec')
          end
        end
      end
    end

    it 'returns valid classified app name' do
      command = Hanami::Commands::New::App.new({}, 'awesome-test-app')
      command.template_options[:classified_app_name].must_equal 'AwesomeTestApp'
    end
  end

  def assert_generated_app(original_wd, test_framework: nil, console_engine: nil)
    fixture_root = original_wd.join('test', 'fixtures', 'commands', 'application', 'new_app')
    Dir.chdir('new_app') do

      if test_framework
        assert_generated_file(fixture_root.join(".hanamirc.#{ test_framework }"), '.hanamirc')
        assert_generated_file(fixture_root.join("Gemfile.#{ test_framework }"), 'Gemfile')
        assert_generated_file(fixture_root.join("Rakefile.#{ test_framework }"), 'Rakefile')
        assert_generated_file(fixture_root.join('spec', "spec_helper.#{ test_framework }.rb"), 'spec/spec_helper.rb')
        assert_generated_file(fixture_root.join('spec', "features_helper.#{ test_framework }.rb"), 'spec/features_helper.rb')
      end

      if console_engine
        assert_generated_file(fixture_root.join(".hanamirc.#{ console_engine }"), '.hanamirc')

        if console_engine != 'irb'
          assert_generated_file(fixture_root.join("Gemfile.#{ console_engine }"), 'Gemfile')
        end
      end

      assert_generated_file(fixture_root.join('.env'), '.env')

      assert_file_includes('.env.development',
                           'NEW_APP_DATABASE_URL="file:///db/new_app_development"',
                           'SERVE_STATIC_ASSETS="true"',
                           %r{NEW_APP_SESSIONS_SECRET="[\w]{64}"})

      assert_file_includes('.env.test',
                           'NEW_APP_DATABASE_URL="file:///db/new_app_test"',
                           'SERVE_STATIC_ASSETS="true"',
                           %r{NEW_APP_SESSIONS_SECRET="[\w]{64}"})

      assert_generated_file(fixture_root.join('config.ru'), 'config.ru')

      assert_generated_file(fixture_root.join('config', 'environment.rb'), 'config/environment.rb')
      assert_generated_file(fixture_root.join('lib', 'new_app.rb'), 'lib/new_app.rb')
      assert_generated_file(fixture_root.join('lib', 'config', 'mapping.rb'), 'lib/config/mapping.rb')
      assert_generated_file(fixture_root.join('config', 'application.rb'), 'config/application.rb')
      assert_generated_file(fixture_root.join('config', 'routes.rb'), 'config/routes.rb')
      assert_generated_file(fixture_root.join('app', 'views', 'application_layout.rb'), 'app/views/application_layout.rb')
      assert_generated_file(fixture_root.join('app', 'templates', 'application.html.erb'), 'app/templates/application.html.erb')

      assert_file_exists('.git')
      assert_file_exists('app/controllers/.gitkeep')
      assert_file_exists('app/views/.gitkeep')
      assert_file_exists('app/assets/favicon.ico')
      assert_file_exists('app/assets/javascripts/.gitkeep')
      assert_file_exists('app/assets/stylesheets/.gitkeep')
      assert_file_exists('app/assets/images/.gitkeep')
      assert_file_exists('config/initializers/.gitkeep')
      assert_file_exists('lib/new_app/entities/.gitkeep')
      assert_file_exists('lib/new_app/repositories/.gitkeep')
      assert_file_exists('lib/new_app/mailers/.gitkeep')
      assert_file_exists('lib/new_app/mailers/templates/.gitkeep')
      assert_file_exists('public/.gitkeep')
      assert_file_exists('db/.gitkeep')
      assert_file_exists('spec/features/.gitkeep')
      assert_file_exists('spec/controllers/.gitkeep')
      assert_file_exists('spec/views/.gitkeep')
      assert_file_exists('spec/new_app/entities/.gitkeep')
      assert_file_exists('spec/new_app/repositories/.gitkeep')
      assert_file_exists('spec/new_app/mailers/.gitkeep')
      assert_file_exists('spec/support/.gitkeep')

      assert_generated_file(fixture_root.join('.gitignore.fixture'), '.gitignore')
    end
  end
end
