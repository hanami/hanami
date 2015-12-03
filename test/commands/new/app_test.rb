require 'test_helper'
require 'lotus/commands/new/app'
require 'fileutils'

describe Lotus::Commands::New::App do
  describe 'with invalid arguments' do
    it 'requires application name' do
      with_temp_dir do |original_wd|
        -> { Lotus::Commands::New::App.new({}, nil) }.must_raise ArgumentError
        -> { Lotus::Commands::New::App.new({}, '') }.must_raise ArgumentError
        -> { Lotus::Commands::New::App.new({}, '  ') }.must_raise ArgumentError
        -> { Lotus::Commands::New::App.new({}, 'foo/bar') }.must_raise ArgumentError
      end
    end

    it 'validates test option' do
      with_temp_dir do |original_wd|
        -> { Lotus::Commands::New::App.new({test: 'unknown'}, nil) }.must_raise ArgumentError
      end
    end

    it 'validates database option' do
      with_temp_dir do |original_wd|
        -> { Lotus::Commands::New::App.new({database: 'unknown'}, nil) }.must_raise ArgumentError
      end
    end

    it 'does not support application_name' do
      with_temp_dir do |original_wd|
        -> { Lotus::Commands::New::App.new({application_name: 'application_name'}, nil) }.must_raise ArgumentError
      end
    end
  end

  describe 'with valid arguments' do
    describe 'minitest' do
      it 'creates files' do
        with_temp_dir do |original_wd|
          command = Lotus::Commands::New::App.new({}, 'new_app')
          capture_io { command.start }

          assert_generated_app('minitest', original_wd)
        end
      end
    end
  end

  describe 'rspec' do
    it 'creates files' do
      with_temp_dir do |original_wd|
        command = Lotus::Commands::New::App.new({'test' => 'rspec'}, 'new_app')
        capture_io { command.start }

        assert_generated_app('rspec', original_wd)
      end
    end
  end

  def assert_generated_app(test_framework, original_wd)
    fixture_root = original_wd.join('test', 'fixtures', 'commands', 'application', 'new_app')
    Dir.chdir('new_app') do
      assert_generated_file(fixture_root.join(".lotusrc.#{ test_framework }"), '.lotusrc')
      assert_generated_file(fixture_root.join('.env'), '.env')

      assert_file_includes('.env.development',
                           'NEW_APP_DATABASE_URL="file:///db/new_app_development"',
                           'SERVE_STATIC_ASSETS="true"',
                           %r{NEW_APP_SESSIONS_SECRET="[\w]{64}"})

      assert_file_includes('.env.test',
                           'NEW_APP_DATABASE_URL="file:///db/new_app_test"',
                           'SERVE_STATIC_ASSETS="true"',
                           %r{NEW_APP_SESSIONS_SECRET="[\w]{64}"})

      assert_generated_file(fixture_root.join("Gemfile.#{ test_framework }"), 'Gemfile')
      assert_generated_file(fixture_root.join('config.ru'), 'config.ru')

      assert_generated_file(fixture_root.join('config', 'environment.rb'), 'config/environment.rb')
      assert_generated_file(fixture_root.join('lib', 'new_app.rb'), 'lib/new_app.rb')
      assert_generated_file(fixture_root.join('lib', 'config', 'mapping.rb'), 'lib/config/mapping.rb')
      assert_generated_file(fixture_root.join('config', 'application.rb'), 'config/application.rb')
      assert_generated_file(fixture_root.join('config', 'routes.rb'), 'config/routes.rb')
      assert_generated_file(fixture_root.join('app', 'views', 'application_layout.rb'), 'app/views/application_layout.rb')
      assert_generated_file(fixture_root.join('app', 'templates', 'application.html.erb'), 'app/templates/application.html.erb')

      assert_generated_file(fixture_root.join("Rakefile.#{ test_framework }"), 'Rakefile')

      assert_generated_file(fixture_root.join('spec', "spec_helper.#{ test_framework }.rb"), 'spec/spec_helper.rb')
      assert_generated_file(fixture_root.join('spec', "features_helper.#{ test_framework }.rb"), 'spec/features_helper.rb')

      assert_file_exists('.git')
      assert_file_exists('app/controllers/.gitkeep')
      assert_file_exists('app/views/.gitkeep')
      assert_file_exists('app/assets/javascripts/.gitkeep')
      assert_file_exists('app/assets/stylesheets/.gitkeep')
      assert_file_exists('app/assets/images/.gitkeep')
      assert_file_exists('config/initializers/.gitkeep')
      assert_file_exists('lib/new_app/entities/.gitkeep')
      assert_file_exists('lib/new_app/repositories/.gitkeep')
      assert_file_exists('lib/new_app/mailers/.gitkeep')
      assert_file_exists('lib/new_app/mailers/templates/.gitkeep')
      assert_file_exists('public/.gitkeep')
      assert_file_exists('public/assets/favicon.ico')
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
