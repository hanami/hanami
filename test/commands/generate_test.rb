require 'test_helper'
require 'lotus/cli'
require 'lotus/commands/generate'

describe Lotus::Commands::Generate do
  let(:opts)     { default_options }
  let(:env)      { Lotus::Environment.new(opts) }
  let(:command)  { Lotus::Commands::Generate.new(target, app_name, target_name, env, cli) }
  let(:cli)      { Lotus::Cli.new }
  let(:app_name) { 'web' }

  def create_temporary_dir
    @tmp = Pathname.new(@pwd = Dir.pwd).join('tmp/generators/generate')
    @tmp.rmtree if @tmp.exist?
    @tmp.mkpath

    @tmp.join('apps', app_name).mkpath

    Dir.chdir(@tmp)
    @root = @tmp
  end

  def chdir_to_root
    Dir.chdir(@pwd)
  end

  def default_options
    Hash[path: 'apps']
  end

  before do
    create_temporary_dir
  end

  after do
    chdir_to_root
  end

  describe 'model' do
    let(:target)      { :model }
    let(:target_name) { '' }
    let(:app_name)    { 'post' }

    before do
      capture_io { command.start }
    end

    describe 'lib/generate/entities/post.rb' do
      it 'generates it' do
        content = @root.join('lib/generate/entities/post.rb').read
        content.must_match %(class Post)
        content.must_match %(  include Lotus::Entity)
        content.must_match %(end)
      end
    end

    describe 'lib/generate/repositories/post.rb' do
      it 'generates it' do
        content = @root.join('lib/generate/repositories/post_repository.rb').read
        content.must_match %(class PostRepository)
        content.must_match %(  include Lotus::Repository)
        content.must_match %(end)
      end
    end

    describe 'spec/generate/entities/post_spec.rb' do
      describe 'minitest (default)' do
        it 'generates it' do
          content = @root.join('spec/generate/entities/post_spec.rb').read
          content.must_match %(require 'spec_helper')
          content.must_match %(describe Post do)
          content.must_match %(end)
        end
      end

      describe 'rspec' do
        let(:opts) { default_options.merge(test: 'rspec') }

        it 'generates it' do
          content = @root.join('spec/generate/entities/post_spec.rb').read
          content.must_match %(require 'spec_helper')
          content.must_match %(RSpec.describe Post do)
          content.must_match %(end)
        end
      end
    end

    describe 'spec/generate/repositories/post_repository_spec.rb' do
      describe 'minitest (default)' do
        it 'generates it' do
          content = @root.join('spec/generate/repositories/post_repository_spec.rb').read
          content.must_match %(require 'spec_helper')
          content.must_match %(describe PostRepository do)
          content.must_match %(end)
        end
      end

      describe 'rspec' do
        let(:opts) { default_options.merge(test: 'rspec') }

        it 'generates it' do
          content = @root.join('spec/generate/repositories/post_repository_spec.rb').read
          content.must_match %(require 'spec_helper')
          content.must_match %(RSpec.describe PostRepository do)
          content.must_match %(end)
        end
      end
    end
  end

  describe 'app' do
    let(:target)      { 'app' }
    let(:target_name) { '' }
    let(:app_name)    { 'admin' }
    let(:environment_config_path) { @root.join('config/environment.rb') }
    let(:environment_development_path) { @root.join('.env.development') }
    let(:environment_test_path) { @root.join('.env.test') }

    before do
      @root.join('config').mkpath
      FileUtils.touch(environment_config_path)
      FileUtils.touch(environment_development_path)
      FileUtils.touch(environment_test_path)
      capture_io { command.start }
    end

    describe 'lib/generate/admin/application.rb' do
      it 'generates it' do
        content = @root.join('apps/admin/application.rb').read
        content.must_match %(require 'lotus/helpers')
        content.must_match %(module Admin)
        content.must_match %(configure do)
        content.must_match %(root __dir__)
        content.must_match %(load_paths << [)
        content.must_match %('controllers',)
        content.must_match %('views')
        content.must_match %(routes 'config/routes')
        content.must_match %(security.x_frame_options "DENY")
        content.must_match %(security.content_security_policy "default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self'; style-src 'self';")
        content.must_match %(controller.prepare do)
        content.must_match %(view.prepare do)
        content.must_match %(include Lotus::Helpers)
        content.must_match %(configure :development)
        content.must_match %(configure :test do)
        content.must_match %(handle_exceptions false)
        content.must_match %(serve_assets      true)
        content.must_match %(configure :production do)
      end
    end
  end
end
