require 'test_helper'
require 'lotus/commands/generate/migration'

describe Lotus::Commands::Generate::Migration do
  let(:opts)    { Hash.new }
  let(:env)     { Lotus::Environment.new(opts) }
  let(:command) { Lotus::Commands::Generate::Migration.new(migration_name, env, cli) }
  let(:cli)     { Lotus::Generate.new }

  def create_temporary_dir
    tmp = Pathname.new(@pwd = Dir.pwd).join('tmp/generators/migration')
    tmp.rmtree if tmp.exist?
    tmp.mkpath

    Dir.chdir(tmp)
    @root = tmp
  end

  def chdir_to_root
    Dir.chdir(@pwd)
  end

  before do
    create_temporary_dir
  end

  after do
    chdir_to_root
  end

  describe '#start' do
    let(:migration_name) { 'create_bird' }
    it 'generates a timestamped migration file' do
      Time.stub :now, Time.new(1970,1,1,23,01,05) do
        capture_io { command.start }
        content = @root.join('db/migrate/19700101230105_create_bird.rb').read
        content.must_match %(class CreateBird < Lotus::Model::Migration) 
      end
    end
  end
end
