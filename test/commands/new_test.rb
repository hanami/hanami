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
      Hash[architecture: 'container', application: 'web', application_base_url: '/', lotus_head: false]
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
        content.must_match %(gem 'lotusrb',      '#{ Lotus::VERSION }')
        content.must_match %(gem 'lotus-model', '~> 0.2')
        content.must_match %(gem 'capybara')
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

      describe 'minitest (default)' do
        it 'includes minitest' do
          content = @root.join('Gemfile').read
          content.must_match %(gem 'minitest')
        end
      end

      describe 'rspec' do
        let(:opts) { container_options.merge(test: 'rspec') }

        it 'includes rspec' do
          content = @root.join('Gemfile').read
          content.must_match %(gem 'rspec')
        end
      end

      describe 'production group' do
        it 'includes a server example' do
          content = @root.join('Gemfile').read
          content.must_match %(group :production do)
          content.must_match %(# gem 'puma')
        end
      end
    end

    describe 'Rakefile' do
      describe 'minitest (default)' do
        it 'generates it' do
          content = @root.join('Rakefile').read
          content.must_match %(Rake::TestTask.new)
          content.must_match %(t.pattern = 'spec/**/*_spec.rb')
          content.must_match %(t.libs    << 'spec')
          content.must_match %(task default: :test)
          content.must_match %(task spec: :test)
        end
      end

      describe 'rspec' do
        let(:opts) { container_options.merge(test: 'rspec') }

        it 'generates it' do
          content = @root.join('Rakefile').read
          content.must_match %(RSpec::Core::RakeTask.new(:spec))
          content.must_match %(task default: :spec)
        end
      end
    end

    describe 'config.ru' do
      it 'generates it' do
        content = @root.join('config.ru').read
        content.must_match %(require './config/environment')
        content.must_match %(run Lotus::Container.new)
      end
    end

    describe 'config/environment.rb' do
      it 'generates it' do
        content = @root.join('config/environment.rb').read
        content.must_match %(require 'rubygems')
        content.must_match %(require 'bundler/setup')
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
        content.must_match 'Dir["#{ __dir__ }/chirp/**/*.rb"].each { |file| require_relative file }'
        content.must_match %(require 'lotus/model')
        content.must_match %(Lotus::Model.configure)
        content.must_match %(adapter type: :file_system, uri: ENV['CHIRP_DATABASE_URL'])
        content.must_match %(mapping do)
        content.must_match %(mapping "{__dir__}/config/mapping")
      end
    end

    describe 'lib/config/mapping.rb' do
      it 'generates it' do
        content = @root.join('lib/config/mapping.rb').read
        content.must_match %(# collection :users do)
        content.must_match %(#   entity     User)
        content.must_match %(#   repository UserRepository)
        content.must_match %(#   attribute :id,   Integer)
        content.must_match %(#   attribute :name, String)
        content.must_match %(# end)
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

    describe 'empty spec/* directory' do
      it 'generates it' do
        @root.join('spec/chirp/entities').must_be :directory?
        @root.join('spec/chirp/repositories').must_be :directory?
        @root.join('spec/support').must_be :directory?
      end
    end

    describe 'testing' do
      describe 'when minitest (default)' do
        describe 'spec/chirp/entities' do
          it 'generates it' do
            @root.join('spec/chirp/entities').must_be :directory?
          end
        end

        describe 'spec/chirp/repositories' do
          it 'generates it' do
            @root.join('spec/chirp/repositories').must_be :directory?
          end
        end

        describe 'spec/spec_helper.rb' do
          describe 'minitest (default)' do
            it 'generates it' do
              content = @root.join('spec/spec_helper.rb').read
              content.must_match %(ENV['LOTUS_ENV'] ||= 'test')
              content.must_match %(require_relative '../config/environment')
              content.must_match %(require 'minitest/autorun')
              content.must_match %(Lotus::Application.preload!)
            end
          end

          describe 'rspec' do
            let(:opts) { container_options.merge(test: 'rspec') }

            it 'generates it' do
              content = @root.join('spec/spec_helper.rb').read
              content.must_match %(ENV['LOTUS_ENV'] ||= 'test')
              content.must_match %(require_relative '../config/environment')
              content.must_match %(RSpec.configure do |config|)
              content.must_match %(config.before(:suite) { Lotus::Application.preload! })
              content.must_match %(config.filter_run :focus)
              content.must_match %(config.run_all_when_everything_filtered = true)

              content.must_match %(if config.files_to_run.one?)
              content.must_match %(config.default_formatter = 'doc')

              content.must_match %(config.order = :random)
              content.must_match %(Kernel.srand config.seed)

              content.must_match %(config.expect_with :rspec do |expectations|)
              content.must_match %(expectations.syntax = :expect)

              content.must_match %(config.mock_with :rspec do |mocks|)
              content.must_match %(mocks.syntax = :expect)
              content.must_match %(mocks.verify_partial_doubles = true)
            end
          end
        end

        describe 'spec/features_helper.rb' do
          describe 'minitest (default)' do
            it 'generates it' do
              content = @root.join('spec/features_helper.rb').read
              content.must_match %(require_relative './spec_helper')
              content.must_match %(require 'capybara')
              content.must_match %(require 'capybara/dsl')
              content.must_match %(Capybara.app = Lotus::Container.new)
              content.must_match %(class MiniTest::Spec)
              content.must_match %(include Capybara::DSL)
            end
          end

          describe 'rspec' do
            let(:opts) { container_options.merge(test: 'rspec') }

            it 'generates it' do
              content = @root.join('spec/features_helper.rb').read
              content.must_match %(require_relative './spec_helper')
              content.must_match %(require 'capybara')
              content.must_match %(require 'capybara/rspec')
              content.must_match %(RSpec.configure do |config|)
              content.must_match %(config.include RSpec::FeatureExampleGroup)
              content.must_match %(config.include Capybara::DSL)
              content.must_match %(config.include Capybara::RSpecMatchers)
            end
          end
        end

        describe 'spec/support/capybara.rb' do
          describe 'rspec' do
            let(:opts) { container_options.merge(test: 'rspec') }

            it 'generates it' do
              content = @root.join('spec/support/capybara.rb').read
              content.must_match %(module RSpec)
              content.must_match %(module FeatureExampleGroup)
              content.must_match %(def self.included(group))
              content.must_match %(group.metadata[:type] = :feature)
              content.must_match %(Capybara.app = Lotus::Container.new)
            end
          end
        end
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

        # main configure block
        content.must_match %(configure do)
        content.must_match %(root __dir__)

        content.must_match %(# adapter type: :file_system, uri: ENV['WEB_DATABASE_URL'])

        content.must_match %(routes 'config/routes')
        content.must_match %(# mapping 'config/mapping')

        content.must_match %(layout :application)
        content.must_match %(# templates 'templates')

        content.must_match %(# cookies true)

        content.must_match %(# sessions :cookie, secret: ENV['WEB_SESSIONS_SECRET'])

        content.must_match %(load_paths << [)
        content.must_match %('controllers')
        content.must_match %('views')

        content.must_match %(# middleware.use Rack::Protection)

        content.must_match %(# body_parsers :json)

        content.must_match %(# assets << [)
        content.must_match %(#   'vendor/javascripts')

        content.must_match %(# serve_assets false)

        content.must_match %(controller.prepare)
        content.must_match %(view.prepare)

        # per environment configuration
        content.must_match %(configure :development do)
        content.must_match %(handle_exceptions false)
        content.must_match %(serve_assets      true)

        content.must_match %(configure :test do)
        content.must_match %(handle_exceptions false)
        content.must_match %(serve_assets      true)

        content.must_match %(configure :production do)
        content.must_match %(# scheme 'https')
        content.must_match %(# host   'example.org')
        content.must_match %(# port   443)
      end
    end

    describe 'apps/web/config/routes.rb' do
      it 'generates it' do
        content = @root.join('apps/web/config/routes.rb').read
        content.must_match %(# Configure your routes here)
        content.must_match %(# get '/', to: 'home#index')
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

    describe 'apps/web/controllers/home/index.rb' do
      it 'generates it' do
        content = @root.join('apps/web/controllers/home/index.rb').read
        content.must_match %(module Web::Controllers::Home)
        content.must_match %(class Index)
        content.must_match %(include Web::Action)
        content.must_match "def call(params)"
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

    describe 'apps/web/views/home/index.rb' do
      it 'generates it' do
        content = @root.join('apps/web/views/home/index.rb').read
        content.must_match %(module Web::Views::Home)
        content.must_match %(class Index)
        content.must_match %(include Web::View)
      end
    end

    describe 'apps/web/templates/home/index.html.rb' do
      it 'generates it' do
        content = @root.join('apps/web/templates/home/index.html.erb').read
        content.must_match %(<h1>Welcome to Lotus!</h1>)
        content.must_match %(<h3>This template is rendered by <code>Web::Views::Home::Index</code> and it's available at: <code>apps/web/templates/home/index.html.erb</code></h3>)
      end
    end

    describe 'apps/web/public/javascripts' do
      it 'generates it' do
        @root.join('apps/web/public/javascripts').must_be :exist?
      end
    end

    describe 'apps/web/public/stylesheets' do
      it 'generates it' do
        @root.join('apps/web/public/stylesheets').must_be :exist?
      end
    end


    describe 'testing' do
      describe 'when minitest (default)' do
        describe 'spec/web/features' do
          it 'generates it' do
            @root.join('spec/web/features').must_be :directory?
          end
        end

        describe 'spec/web/controllers' do
          it 'generates it' do
            @root.join('spec/web/controllers').must_be :directory?
          end
        end

        describe 'spec/web/views' do
          it 'generates it' do
            @root.join('spec/web/views').must_be :directory?
          end
        end
      end
    end

    describe 'when app_name is .' do
      let(:app_name) { '.' }

      describe 'config/environment.rb' do
        it 'generates it' do
          content = @root.join('config/environment.rb').read
          content.must_match %(require_relative '../lib/new')
        end
      end

      describe 'lib/new' do
        it 'generates it' do
          @root.join('lib/new').must_be :directory?
        end
      end

      describe 'lib/new.rb' do
        it 'generates it' do
          @root.join('lib/new.rb').must_be :file?
          content = @root.join('lib/new.rb').read
          content.must_match %(adapter type: :file_system, uri: ENV['NEW_DATABASE_URL'])
        end
      end

      describe 'config/.env.development' do
        it 'generates it' do
          content = @root.join('config/.env.development').read
          content.must_match %(NEW_DATABASE_URL="file:///db/new_development")
        end
      end

      describe 'config/.env.test' do
        it 'generates it' do
          content = @root.join('config/.env.test').read
          content.must_match %(NEW_DATABASE_URL="file:///db/new_test")
        end
      end
    end

    describe 'application path' do
      describe 'when an application path is provided' do
        let(:opts) { container_options.merge(application_path: 'my_lotus_app') }

        describe 'my_lotus_app' do
          it 'generates it' do
            @root.dirname().join('my_lotus_app').must_be :directory?
          end
        end
      end
    end
  end
end
