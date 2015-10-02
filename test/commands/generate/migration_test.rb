require 'test_helper'
require 'lotus/commands/generate/migration'
require 'fileutils'

describe Lotus::Commands::Generate::Migration do
  describe 'with invalid arguments' do
    it 'requires migration name' do
      with_temp_dir do
        setup_app
        -> { Lotus::Commands::Generate::Migration.new({}, nil) }.must_raise ArgumentError
        -> { Lotus::Commands::Generate::Migration.new({}, '') }.must_raise ArgumentError
        -> { Lotus::Commands::Generate::Migration.new({}, '   ') }.must_raise ArgumentError
      end
    end
  end

  describe 'with valid arguments' do
    it 'creates the migration file' do
      with_temp_dir do |original_wd|
        setup_app
        command = Lotus::Commands::Generate::Migration.new({}, 'something')
        capture_io { command.start }
        files = Dir.glob('db/migrations/*_something.rb')

        assert 1, files.size
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/migration/migration.rb'), files.first)
      end
    end

    it 'underscores the migration name' do
      with_temp_dir do |original_wd|
        setup_app
        command = Lotus::Commands::Generate::Migration.new({}, 'SoMe-Thing-Strange')
        capture_io { command.start }
        files = Dir.glob('db/migrations/*_so_me_thing_strange.rb')
        assert 1, files.size
      end
    end
  end

  def setup_app
    # provide minimal files so it actually looks like an app
    FileUtils.mkdir_p('config')
    FileUtils.touch('config/environment.rb')
  end
end
