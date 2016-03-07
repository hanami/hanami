require 'test_helper'
require 'hanami/commands/generate/migration'
require 'fileutils'

describe Hanami::Commands::Generate::Migration do
  describe 'with invalid arguments' do
    it 'requires migration name' do
      with_temp_dir do
        setup_app
        message = 'Migration name is missing'
        assert_exception_raised(ArgumentError, message) do
          Hanami::Commands::Generate::Migration.new({}, nil)
        end
        assert_exception_raised(ArgumentError, message) do
          Hanami::Commands::Generate::Migration.new({}, '')
        end
        assert_exception_raised(ArgumentError, message) do
          Hanami::Commands::Generate::Migration.new({}, '   ')
        end
      end
    end
  end

  describe 'with valid arguments' do
    it 'creates the migration file' do
      with_temp_dir do |original_wd|
        setup_app
        command = Hanami::Commands::Generate::Migration.new({}, 'something')
        capture_io { command.start }

        assert_migration_exists('something')

        files = Dir.glob('db/migrations/*_something.rb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/migration/migration.rb'), files.first)
      end
    end

    it 'underscores the migration name' do
      with_temp_dir do |original_wd|
        setup_app
        command = Hanami::Commands::Generate::Migration.new({}, 'SoMe-Thing-Strange')
        capture_io { command.start }

        assert_migration_exists('so_me_thing_strange')
      end
    end
  end

  describe '#destroy' do
    it 'destroys the migration file' do
      with_temp_dir do |original_wd|
        setup_app

        capture_io {
          Hanami::Commands::Generate::Migration.new({}, 'create_books').start

          Hanami::Commands::Generate::Migration.new({}, 'create_users').start

          Hanami::Commands::Generate::Migration.new({}, 'create_books').destroy.start
        }

        assert_migration_exists('create_users')

        refute_migration_exists('create_books')
      end
    end
  end

  def assert_migration_exists(name)
    assert Dir.glob("db/migrations/[0-9]*_#{name}.rb").any?, "Expected migration #{name} to exist but does not."
  end

  def refute_migration_exists(name)
    refute Dir.glob("db/migrations/[0-9]*_#{name}.rb").any?, "Expected migration #{name} to NOT exist but does."
  end

  def setup_app
    # provide minimal files so it actually looks like an app
    FileUtils.mkdir_p('config')
    FileUtils.touch('config/environment.rb')
  end
end
