require 'test_helper'
require 'lotus/commands/new/container'
require 'fileutils'

describe Lotus::Commands::New::Container do
  describe 'with invalid arguments' do
    it 'requires application name' do
      with_temp_dir do |original_wd|
        -> { Lotus::Commands::New::Container.new({}, nil) }.must_raise ArgumentError
        -> { Lotus::Commands::New::Container.new({}, '') }.must_raise ArgumentError
        -> { Lotus::Commands::New::Container.new({}, '  ') }.must_raise ArgumentError
        -> { Lotus::Commands::New::Container.new({}, 'foo/bar') }.must_raise ArgumentError
      end
    end

    it 'validates test option' do
      with_temp_dir do |original_wd|
        -> { Lotus::Commands::New::Container.new({test: 'unknown'}, nil) }.must_raise ArgumentError
      end
    end

    it 'validates database option' do
      with_temp_dir do |original_wd|
        -> { Lotus::Commands::New::Container.new({database: 'unknown'}, nil) }.must_raise ArgumentError
      end
    end
  end

  describe 'with valid arguments' do
    it 'application name with dash' do
      with_temp_dir do |original_wd|
        command = Lotus::Commands::New::Container.new({}, 'new-container')
        capture_io { command.start }
        Dir.chdir('new-container') do
          actual_content = File.read('.env.development')
          actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="file:///db/new-container_development"'

          actual_content = File.read('.env.test')
          actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="file:///db/new-container_test"'
        end
      end
    end

    describe 'application name is a point' do
      it 'generates application in current folder' do
        with_temp_dir do |original_wd|
         command = Lotus::Commands::New::Container.new({}, '.')
          capture_io { command.start }
          Dir.chdir('.') do
            actual_content = File.read('.env.development')
            actual_content.must_include 'TESTAPP_DATABASE_URL="file:///db/testapp_development"'

            actual_content = File.read('.env.test')
            actual_content.must_include 'TESTAPP_DATABASE_URL="file:///db/testapp_test"'
          end
        end
      end
    end

    describe 'databases' do
      it 'generates specific files for memory' do
        with_temp_dir do |original_wd|
          command = Lotus::Commands::New::Container.new({database: 'memory'}, 'new_container')
          capture_io { command.start }

          fixture_root = original_wd.join('test', 'fixtures', 'commands', 'application', 'new_container')
          Dir.chdir('new_container') do
            actual_content = File.read('.env.development')
            actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="memory://localhost/new_container_development"'

            actual_content = File.read('.env.test')
            actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="memory://localhost/new_container_test"'

            assert_generated_file(fixture_root.join('Gemfile.memory'), 'Gemfile')
            assert_generated_file(fixture_root.join('lib', 'new_container.memory.rb'), 'lib/new_container.rb')
            assert_file_exists('db/.gitkeep')
          end
        end
      end

      it 'generates specific files for filesystem' do
        with_temp_dir do |original_wd|
          command = Lotus::Commands::New::Container.new({database: 'filesystem'}, 'new_container')
          capture_io { command.start }

          fixture_root = original_wd.join('test', 'fixtures', 'commands', 'application', 'new_container')
          Dir.chdir('new_container') do
            actual_content = File.read('.env.development')
            actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="file:///db/new_container_development"'

            actual_content = File.read('.env.test')
            actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="file:///db/new_container_test"'

            assert_generated_file(fixture_root.join('Gemfile.filesystem'), 'Gemfile')
            assert_generated_file(fixture_root.join('lib', 'new_container.filesystem.rb'), 'lib/new_container.rb')
            assert_file_exists('db/.gitkeep')
          end
        end
      end

      it 'generates specific files for sqlite3' do
        with_temp_dir do |original_wd|
          command = Lotus::Commands::New::Container.new({database: 'sqlite3'}, 'new_container')
          capture_io { command.start }

          fixture_root = original_wd.join('test', 'fixtures', 'commands', 'application', 'new_container')
          Dir.chdir('new_container') do
            actual_content = File.read('.env.development')
            actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="sqlite://db/new_container_development.sqlite"'

            actual_content = File.read('.env.test')
            actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="sqlite://db/new_container_test.sqlite"'

            assert_generated_file(fixture_root.join('Gemfile.sqlite3'), 'Gemfile')
            assert_generated_file(fixture_root.join('lib', 'new_container.sqlite3.rb'), 'lib/new_container.rb')
            assert_file_exists('db/migrations/.gitkeep')
          end
        end
      end

      it 'generates specific files for postgres' do
        with_temp_dir do |original_wd|
          command = Lotus::Commands::New::Container.new({database: 'postgres'}, 'new_container')
          capture_io { command.start }

          fixture_root = original_wd.join('test', 'fixtures', 'commands', 'application', 'new_container')
          Dir.chdir('new_container') do
            actual_content = File.read('.env.development')
            actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="postgres://localhost/new_container_development"'

            actual_content = File.read('.env.test')
            actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="postgres://localhost/new_container_test"'

            assert_generated_file(fixture_root.join('Gemfile.postgres'), 'Gemfile')
            assert_generated_file(fixture_root.join('lib', 'new_container.postgres.rb'), 'lib/new_container.rb')
            assert_file_exists('db/migrations/.gitkeep')
          end
        end
      end

      it 'generates specific files for mysql2' do
        with_temp_dir do |original_wd|
          command = Lotus::Commands::New::Container.new({database: 'mysql2'}, 'new_container')
          capture_io { command.start }

          fixture_root = original_wd.join('test', 'fixtures', 'commands', 'application', 'new_container')
          Dir.chdir('new_container') do
            actual_content = File.read('.env.development')
            actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="mysql2://localhost/new_container_development"'

            actual_content = File.read('.env.test')
            actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="mysql2://localhost/new_container_test"'

            assert_generated_file(fixture_root.join('Gemfile.mysql2'), 'Gemfile')
            assert_generated_file(fixture_root.join('lib', 'new_container.mysql2.rb'), 'lib/new_container.rb')
            assert_file_exists('db/migrations/.gitkeep')
          end
        end
      end

      it 'generates specific files for postgres' do
        with_temp_dir do |original_wd|
          command = Lotus::Commands::New::Container.new({database: 'postgres'}, 'new_container')
          capture_io { command.start }

          fixture_root = original_wd.join('test', 'fixtures', 'commands', 'application', 'new_container')
          Dir.chdir('new_container') do
            actual_content = File.read('.env.development')
            actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="postgres://localhost/new_container_development"'

            actual_content = File.read('.env.test')
            actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="postgres://localhost/new_container_test"'

            assert_generated_file(fixture_root.join('Gemfile.postgres'), 'Gemfile')
            assert_generated_file(fixture_root.join('lib', 'new_container.postgres.rb'), 'lib/new_container.rb')
            assert_file_exists('db/migrations/.gitkeep')
          end
        end
      end
    end

    describe 'lotus head' do
      it 'creates files' do
        with_temp_dir do |original_wd|
          command = Lotus::Commands::New::Container.new({lotus_head: true}, 'new_container')
          capture_io { command.start }

          fixture_root = original_wd.join('test', 'fixtures', 'commands', 'application', 'new_container')
          Dir.chdir('new_container') do
            assert_generated_file(fixture_root.join('Gemfile.head'), 'Gemfile')
          end
        end
      end
    end

    describe 'mounted at a specific path' do
      it 'mounts at /mypath' do
        with_temp_dir do |original_wd|
          command = Lotus::Commands::New::Container.new({application_base_url: '/mypath'}, 'new_container')
          capture_io { command.start }
          fixture_root = original_wd.join('test', 'fixtures', 'commands', 'application', 'new_container')
          Dir.chdir('new_container') do
            assert_generated_file(fixture_root.join('config', 'environment_mypath.rb'), 'config/environment.rb')
          end
        end
      end
    end

    describe 'with rspec' do
      it 'creates the app files' do
        with_temp_dir do |original_wd|
          command = Lotus::Commands::New::Container.new({test: 'rspec'}, 'new_container')
          capture_io { command.start }

          assert_generated_container('rspec', original_wd)
        end
      end
    end

    describe 'with minitest' do
      it 'creates files' do
        with_temp_dir do |original_wd|
          command = Lotus::Commands::New::Container.new({}, 'new_container')
          capture_io { command.start }

          assert_generated_container('minitest', original_wd)
        end
      end
    end
  end

  def assert_generated_container(test_framework, original_wd)
    fixture_root = original_wd.join('test', 'fixtures', 'commands', 'application', 'new_container')
    Dir.chdir('new_container') do
      assert_generated_file(fixture_root.join(".lotusrc.#{ test_framework }"), '.lotusrc')
      assert_generated_file(fixture_root.join('.env'), '.env')
      actual_content = File.read('.env.development')
      actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="file:///db/new_container_development"'
      actual_content.must_match(%r{WEB_SESSIONS_SECRET="[\w]{64}"})

      actual_content = File.read('.env.test')
      actual_content.must_include 'NEW_CONTAINER_DATABASE_URL="file:///db/new_container_test"'
      actual_content.must_match %r{WEB_SESSIONS_SECRET="[\w]{64}"}

      assert_generated_file(fixture_root.join("Gemfile.#{ test_framework }"), 'Gemfile')
      assert_generated_file(fixture_root.join('config.ru'), 'config.ru')

      assert_generated_file(fixture_root.join('config', 'environment.rb'), 'config/environment.rb')
      assert_generated_file(fixture_root.join('lib', 'new_container.rb'), 'lib/new_container.rb')
      assert_generated_file(fixture_root.join('lib', 'config', 'mapping.rb'), 'lib/config/mapping.rb')
      assert_file_exists('lib/new_container/entities/.gitkeep')
      assert_file_exists('lib/new_container/repositories/.gitkeep')
      assert_file_exists('lib/new_container/mailers/.gitkeep')
      assert_file_exists('lib/new_container/mailers/templates/.gitkeep')
      assert_file_exists('spec/new_container/entities/.gitkeep')
      assert_file_exists('spec/new_container/repositories/.gitkeep')
      assert_file_exists('spec/new_container/mailers/.gitkeep')
      assert_file_exists('spec/support/.gitkeep')
      assert_file_exists('db/.gitkeep')
      assert_file_exists('.git')
      assert_generated_file(fixture_root.join("Rakefile.#{ test_framework }"), 'Rakefile')
      assert_generated_file(fixture_root.join('spec', "spec_helper.#{ test_framework }.rb"), 'spec/spec_helper.rb')
      assert_generated_file(fixture_root.join('spec', "features_helper.#{ test_framework }.rb"), 'spec/features_helper.rb')
      assert_generated_file(fixture_root.join('.gitignore.fixture'), '.gitignore')
      # other files are tested by app generator
    end
  end
end
