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

  describe 'action' do
    let(:target)      { :action }
    let(:target_name) { 'dashboard#index' }

    describe 'with valid arguments' do
      before do
        capture_io { command.start }
      end

      describe 'apps/web/config/routes.rb' do
        it 'generates it' do
          content = @root.join('apps/web/config/routes.rb').read
          content.must_match %(get '/dashboard', to: 'dashboard#index')
        end
      end

      describe 'apps/web/controllers/dashboard/index.rb' do
        it 'generates it' do
          content = @root.join('apps/web/controllers/dashboard/index.rb').read
          content.must_match %(module Web::Controllers::Dashboard)
          content.must_match %(  class Index)
          content.must_match %(    include Web::Action)
          content.must_match %(    def call(params))
          content.wont_match %(      self.body = 'OK')
        end
      end

      describe 'spec/web/controllers/dashboard/index_spec.rb' do
        describe 'minitest (default)' do
          it 'generates it' do
            content = @root.join('spec/web/controllers/dashboard/index_spec.rb').read
            content.must_match %(require 'spec_helper')
            content.must_match %(require_relative '../../../../apps/web/controllers/dashboard/index')
            content.must_match %(describe Web::Controllers::Dashboard::Index do)
            content.must_match %(  let(:action) { Web::Controllers::Dashboard::Index.new })
            content.must_match %(  let(:params) { Hash[] })
            content.must_match %(  it "is successful" do)
            content.must_match %(    response = action.call(params))
            content.must_match %(    response[0].must_equal 200)
          end
        end

        describe 'rspec' do
          let(:opts) { default_options.merge(test: 'rspec') }

          it 'generates it' do
            content = @root.join('spec/web/controllers/dashboard/index_spec.rb').read
            content.must_match %(require 'spec_helper')
            content.must_match %(require_relative '../../../../apps/web/controllers/dashboard/index')
            content.must_match %(describe Web::Controllers::Dashboard::Index do)
            content.must_match %(  let(:action) { Web::Controllers::Dashboard::Index.new })
            content.must_match %(  let(:params) { Hash[] })
            content.must_match %(  it "is successful" do)
            content.must_match %(    response = action.call(params))
            content.must_match %(    expect(response[0]).to eq 200)
          end
        end
      end

      describe 'apps/web/views/dashboard/index.rb' do
        it 'generates it' do
          content = @root.join('apps/web/views/dashboard/index.rb').read
          content.must_match %(module Web::Views::Dashboard)
          content.must_match %(  class Index)
          content.must_match %(    include Web::View)
        end
      end

      describe 'spec/web/views/dashboard/index_spec.rb' do
        describe 'minitest (default)' do
          it 'generates it' do
            content = @root.join('spec/web/views/dashboard/index_spec.rb').read
            content.must_match %(require 'spec_helper')
            content.must_match %(require_relative '../../../../apps/web/views/dashboard/index')
            content.must_match %(describe Web::Views::Dashboard::Index do)
            content.must_match %(  let(:exposures) { Hash[foo: 'bar'] })
            content.must_match %(  let(:template)  { Lotus::View::Template.new('apps/web/templates/dashboard/index.html.erb') })
            content.must_match %(  let(:view)      { Web::Views::Dashboard::Index.new(template, exposures) })
            content.must_match %(  let(:rendered)  { view.render })
            content.must_match %(  it "exposes #foo" do)
            content.must_match %(    view.foo.must_equal exposures.fetch(:foo))
            content.must_match %(  end)
          end
        end

        describe 'rspec' do
          let(:opts) { default_options.merge(test: 'rspec') }

          it 'generates it' do
            content = @root.join('spec/web/views/dashboard/index_spec.rb').read
            content.must_match %(require 'spec_helper')
            content.must_match %(require_relative '../../../../apps/web/views/dashboard/index')
            content.must_match %(describe Web::Views::Dashboard::Index do)
            content.must_match %(  let(:exposures) { Hash[foo: 'bar'] })
            content.must_match %(  let(:template)  { Lotus::View::Template.new('apps/web/templates/dashboard/index.html.erb') })
            content.must_match %(  let(:view)      { Web::Views::Dashboard::Index.new(template, exposures) })
            content.must_match %(  let(:rendered)  { view.render })
            content.must_match %(  it "exposes #foo" do)
            content.must_match %(    expect(view.foo).to eq exposures.fetch(:foo))
            content.must_match %(  end)
          end
        end
      end

      describe 'apps/web/templates/dashboard/index.html.erb' do
        it 'generates it' do
          content = @root.join('apps/web/templates/dashboard/index.html.erb').read
          content.must_be :empty?
        end
      end
    end

    # See https://github.com/lotus/lotus/issues/282
    describe 'with quoted name' do
      let(:target_name) { "'authors#index'" }

      before do
        capture_io { command.start }
      end

      describe 'apps/web/config/routes.rb' do
        it 'generates it' do
          content = @root.join('apps/web/config/routes.rb').read
          content.must_match %(get '/authors', to: 'authors#index')
        end
      end

      describe 'apps/web/controllers/authors/index.rb' do
        it 'generates it' do
          content = @root.join('apps/web/controllers/authors/index.rb').read
          content.must_match %(module Web::Controllers::Authors)
        end
      end

      describe 'spec/web/controllers/authors/index_spec.rb' do
        it 'generates it' do
          content = @root.join('spec/web/controllers/authors/index_spec.rb').read
          content.must_match %(require 'spec_helper')
          content.must_match %(require_relative '../../../../apps/web/controllers/authors/index')
          content.must_match %(describe Web::Controllers::Authors::Index do)
          content.must_match %(  let(:action) { Web::Controllers::Authors::Index.new })
        end
      end

      describe 'apps/web/views/authors/index.rb' do
        it 'generates it' do
          content = @root.join('apps/web/views/authors/index.rb').read
          content.must_match %(module Web::Views::Authors)
        end
      end

      describe 'spec/web/views/authors/index_spec.rb' do
        it 'generates it' do
          content = @root.join('spec/web/views/authors/index_spec.rb').read
          content.must_match %(require 'spec_helper')
          content.must_match %(require_relative '../../../../apps/web/views/authors/index')
          content.must_match %(describe Web::Views::Authors::Index do)
          content.must_match %(  let(:template)  { Lotus::View::Template.new('apps/web/templates/authors/index.html.erb') })
          content.must_match %(  let(:view)      { Web::Views::Authors::Index.new(template, exposures) })
        end
      end

      describe 'apps/web/templates/authors/index.html.erb' do
        it 'generates it' do
          content = @root.join('apps/web/templates/authors/index.html.erb').read
          content.must_be :empty?
        end
      end
    end

    # See https://github.com/lotus/lotus/issues/282
    describe 'with double quoted name' do
      let(:target_name) { '"authors#index"' }

      before do
        capture_io { command.start }
      end

      describe 'apps/web/config/routes.rb' do
        it 'generates it' do
          content = @root.join('apps/web/config/routes.rb').read
          content.must_match %(get '/authors', to: 'authors#index')
        end
      end

      describe 'apps/web/controllers/authors/index.rb' do
        it 'generates it' do
          content = @root.join('apps/web/controllers/authors/index.rb').read
          content.must_match %(module Web::Controllers::Authors)
        end
      end

      describe 'spec/web/controllers/authors/index_spec.rb' do
        it 'generates it' do
          content = @root.join('spec/web/controllers/authors/index_spec.rb').read
          content.must_match %(require 'spec_helper')
          content.must_match %(require_relative '../../../../apps/web/controllers/authors/index')
          content.must_match %(describe Web::Controllers::Authors::Index do)
          content.must_match %(  let(:action) { Web::Controllers::Authors::Index.new })
        end
      end

      describe 'apps/web/views/authors/index.rb' do
        it 'generates it' do
          content = @root.join('apps/web/views/authors/index.rb').read
          content.must_match %(module Web::Views::Authors)
        end
      end

      describe 'spec/web/views/authors/index_spec.rb' do
        it 'generates it' do
          content = @root.join('spec/web/views/authors/index_spec.rb').read
          content.must_match %(require 'spec_helper')
          content.must_match %(require_relative '../../../../apps/web/views/authors/index')
          content.must_match %(describe Web::Views::Authors::Index do)
          content.must_match %(  let(:template)  { Lotus::View::Template.new('apps/web/templates/authors/index.html.erb') })
          content.must_match %(  let(:view)      { Web::Views::Authors::Index.new(template, exposures) })
        end
      end

      describe 'apps/web/templates/authors/index.html.erb' do
        it 'generates it' do
          content = @root.join('apps/web/templates/authors/index.html.erb').read
          content.must_be :empty?
        end
      end
    end

    # See https://github.com/lotus/lotus/issues/282
    describe 'with escaped name' do
      let(:target_name) { 'authors\#index' }

      before do
        capture_io { command.start }
      end

      describe 'apps/web/config/routes.rb' do
        it 'generates it' do
          content = @root.join('apps/web/config/routes.rb').read
          content.must_match %(get '/authors', to: 'authors#index')
        end
      end

      describe 'apps/web/controllers/authors/index.rb' do
        it 'generates it' do
          content = @root.join('apps/web/controllers/authors/index.rb').read
          content.must_match %(module Web::Controllers::Authors)
        end
      end

      describe 'spec/web/controllers/authors/index_spec.rb' do
        it 'generates it' do
          content = @root.join('spec/web/controllers/authors/index_spec.rb').read
          content.must_match %(require 'spec_helper')
          content.must_match %(require_relative '../../../../apps/web/controllers/authors/index')
          content.must_match %(describe Web::Controllers::Authors::Index do)
          content.must_match %(  let(:action) { Web::Controllers::Authors::Index.new })
        end
      end

      describe 'apps/web/views/authors/index.rb' do
        it 'generates it' do
          content = @root.join('apps/web/views/authors/index.rb').read
          content.must_match %(module Web::Views::Authors)
        end
      end

      describe 'spec/web/views/authors/index_spec.rb' do
        it 'generates it' do
          content = @root.join('spec/web/views/authors/index_spec.rb').read
          content.must_match %(require 'spec_helper')
          content.must_match %(require_relative '../../../../apps/web/views/authors/index')
          content.must_match %(describe Web::Views::Authors::Index do)
          content.must_match %(  let(:template)  { Lotus::View::Template.new('apps/web/templates/authors/index.html.erb') })
          content.must_match %(  let(:view)      { Web::Views::Authors::Index.new(template, exposures) })
        end
      end

      describe 'apps/web/templates/authors/index.html.erb' do
        it 'generates it' do
          content = @root.join('apps/web/templates/authors/index.html.erb').read
          content.must_be :empty?
        end
      end
    end

    describe 'with --skip-view flag' do
      let(:opts) { default_options.merge(skip_view: true) }

      before do
        capture_io { command.start }
      end

      describe 'apps/web/controllers/dashboard/index.rb' do
        it 'generates it' do
          content = @root.join('apps/web/controllers/dashboard/index.rb').read
          content.must_match %(module Web::Controllers::Dashboard)
          content.must_match %(  class Index)
          content.must_match %(    include Web::Action)
          content.must_match %(    def call(params))
          content.must_match %(      self.body = 'OK')
        end
      end

      describe 'apps/web/views/dashboard/index.rb' do
        it 'does not generate it' do
          @root.join('apps/web/views/dashboard/index.rb').exist?.must_be_same_as false
        end
      end

      describe 'apps/web/templates/dashboard/index.html.erb' do
        it 'does not generate it' do
          @root.join('apps/web/views/dashboard/index.rb').exist?.must_be_same_as false
        end
      end

      describe 'spec/web/views/dashboard/index_spec.rb' do
        it 'does not generate it' do
          @root.join('spec/web/views/dashboard/index_spec.rb').exist?.must_be_same_as false
        end
      end
    end

    describe 'with unknown app' do
      before do
        # force not-existing app
        @tmp.join('apps', app_name).rmtree
      end

      let(:app_name) { 'unknown' }

      it 'raises error' do
        -> { capture_io { command.start } }.must_raise SystemExit
      end
    end

    describe 'without action name' do
      let(:target_name) { 'users' }

      it 'raises error' do
        -> { capture_io { command.start } }.must_raise SystemExit
      end
    end
  end

  describe 'model' do
    let(:target)      { :model }
    let(:target_name) { '' }
    let(:app_name)    { 'post' }

    describe 'with valid arguments' do
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

    describe 'without model name' do
      let(:app_name) { '' }

      it 'raises error' do
        -> { capture_io { command.start } }.must_raise SystemExit
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
