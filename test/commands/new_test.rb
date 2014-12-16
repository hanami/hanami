require 'test_helper'
require 'lotus/cli'
require 'lotus/commands/new'

describe Lotus::Commands::New do
  let(:opts)    { Hash.new }
  let(:env)     { Lotus::Environment.new(opts) }
  let(:command) { Lotus::Commands::New.new(app_name, env, cli) }
  let(:cli)     { Lotus::Cli.new }

  def create_temporary_dir
    tmp = Pathname.new(@pwd = Dir.pwd).join('tmp/generators/new')
    tmp.rmtree if tmp.exist?
    tmp.mkpath

    Dir.chdir(tmp)
    @root = tmp.join(app_name)
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

  describe 'container architecture' do
    def container_options
      Hash[architecture: 'container', slice: 'web', slice_base_url: '/', lotus_head: false]
    end

    let(:opts)     { container_options }
    let(:app_name) { 'chirp' }

    before do
      capture_io { command.start }
    end

    describe 'Gemfile' do
      it 'generates it' do
        content = @root.join('Gemfile').read
        content.must_match %(gem 'bundler')
        content.must_match %(gem 'rake')
        content.must_match %(gem 'lotusrb',     '#{ Lotus::VERSION }')
        content.must_match %(gem 'lotus-model', '>= 0.2.0.dev')
      end

      describe 'lotus-head option' do
        let(:opts) { container_options.merge(lotus_head: true) }

        it 'generates it' do
          content = @root.join('Gemfile').read
          content.must_match %(gem 'bundler')
          content.must_match %(gem 'rake')
          content.must_match %(gem 'lotus-utils',       require: false, github: 'lotus/utils')
          content.must_match %(gem 'lotus-router',      require: false, github: 'lotus/router')
          content.must_match %(gem 'lotus-validations', require: false, github: 'lotus/validations')
          content.must_match %(gem 'lotus-controller',  require: false, github: 'lotus/controller')
          content.must_match %(gem 'lotus-view',        require: false, github: 'lotus/view')
          content.must_match %(gem 'lotus-model',       require: false, github: 'lotus/model')
          content.must_match %(gem 'lotusrb',                           github: 'lotus/lotus')
        end
      end
    end

    describe 'Rakefile' do
      describe 'minitest (default)' do
        it 'generates it' do
          content = @root.join('Rakefile').read
          content.must_match %(Rake::TestTask.new)
          content.must_match %(t.pattern = 'test/**/*_test.rb')
          content.must_match %(task default: :test)
        end
      end
    end

    describe 'config.ru' do
      it 'generates it' do
        content = @root.join('config.ru').read
        content.must_match %(require_relative 'config/environment')
        content.must_match %(run Lotus::Container.new)
      end
    end

    describe 'config/environment.rb' do
      it 'generates it' do
        content = @root.join('config/environment.rb').read
        content.must_match %(require 'lotus/setup')
        content.must_match %(require_relative '../lib/chirp')

        content.must_match %(Lotus::Container.configure)
      end
    end

    describe 'config/.env' do
      it 'generates it' do
        content = @root.join('config/.env').read
        content.must_match %(# Define ENV variables)
      end
    end

    describe 'config/.env.development' do
      it 'generates it' do
        content = @root.join('config/.env.development').read
        content.must_match %(# Define ENV variables for development environment)
        content.must_match %(CHIRP_DATABASE_URL="file:///db/chirp_development")
      end
    end

    describe 'config/.env.test' do
      it 'generates it' do
        content = @root.join('config/.env.test').read
        content.must_match %(# Define ENV variables for test environment)
        content.must_match %(CHIRP_DATABASE_URL="file:///db/chirp_test")
      end
    end

    describe 'lib/chirp.rb' do
      it 'generates it' do
        content = @root.join('lib/chirp.rb').read
        content.must_match 'Dir["#{ __dir__ }/**/*.rb"].each {|file| require_relative file }'
        content.must_match %(require 'lotus/model')
        content.must_match %(Lotus::Model.configure)
        content.must_match %(adapter type: :file_system, uri: ENV['CHIRP_DATABASE_URL'])
        content.must_match %(mapping do)
      end
    end

    describe 'db' do
      it 'generates it' do
        @root.join('db').must_be :directory?
      end
    end

    describe 'lib/chirp/entities' do
      it 'generates it' do
        @root.join('lib/chirp/entities').must_be :directory?
      end
    end

    describe 'lib/chirp/repositories' do
      it 'generates it' do
        @root.join('lib/chirp/repositories').must_be :directory?
      end
    end

    ################
    # SLICE
    ################

    describe 'config/environment.rb' do
      it 'patches the file to reference slice' do
        content = @root.join('config/environment.rb').read
        content.must_match %(require_relative '../apps/web/application')
        content.must_match %(mount Web::Application, at: '/')
      end
    end

    describe 'config/.env.development' do
      it 'patches the file to reference slice env vars' do
        content = @root.join('config/.env.development').read
        content.must_match %(WEB_DATABASE_URL="file:///db/web_development")
        content.must_match %r{WEB_SESSIONS_SECRET="[\w]{64}"}
      end
    end

    describe 'config/.env.test' do
      it 'patches the file to reference slice env vars' do
        content = @root.join('config/.env.test').read
        content.must_match %(WEB_DATABASE_URL="file:///db/web_test")
        content.must_match %r{WEB_SESSIONS_SECRET="[\w]{64}"}
      end
    end

    describe 'apps/web/application.rb' do
      it 'generates it' do
        content = @root.join('apps/web/application.rb').read
        content.must_match %(module Web)
        content.must_match %(class Application < Lotus::Application)

        content.must_match %(configure do)
        content.must_match %(root __dir__)

        content.must_match %(# adapter type: :file_system, uri: ENV['WEB_DATABASE_URL'])

        content.must_match %(routes  'config/routes')
        content.must_match %(# mapping 'config/mapping')

        content.must_match %(layout :application)

        content.must_match %(# cookies true)

        content.must_match %(# sessions :cookie, secret: ENV['WEB_SESSIONS_SECRET'])

        content.must_match %(load_paths << [)
        content.must_match %('controllers')
        content.must_match %('views')

        content.must_match %(controller.prepare)
        content.must_match %(view.prepare)
      end
    end

    describe 'apps/web/config/routes.rb' do
      it 'generates it' do
        content = @root.join('apps/web/config/routes.rb').read
        content.must_match %(# Configure your routes here)
      end
    end

    describe 'apps/web/config/mapping.rb' do
      it 'generates it' do
        content = @root.join('apps/web/config/mapping.rb').read
        content.must_match %(# Configure your database mapping here)
      end
    end

    describe 'apps/web/controllers' do
      it 'generates it' do
        @root.join('apps/web/controllers').must_be :exist?
      end
    end

    describe 'apps/web/views/application_layout.rb' do
      it 'generates it' do
        content = @root.join('apps/web/views/application_layout.rb').read
        content.must_match %(module Web)
        content.must_match %(module Views)
        content.must_match %(class ApplicationLayout)
        content.must_match %(include Web::Layout)
      end
    end

    describe 'apps/web/templates/application.html.rb' do
      it 'generates it' do
        content = @root.join('apps/web/templates/application.html.erb').read
        content.must_match %(<title>Web</title>)
        content.must_match %(<%= yield %>)
      end
    end
  end
end
