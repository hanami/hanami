require 'test_helper'
require 'lotus/cli'
require 'lotus/commands/new'

describe Lotus::Commands::New do
  let(:opts)    { Hash.new }
  let(:env)     { Lotus::Environment.new(opts) }
  let(:command) { Lotus::Commands::New.new(app_name, env, cli) }
  let(:cli)     { Lotus::Cli.new }
  let(:architecture) { 'container' }

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
      Hash[architecture: architecture, application: 'web', application_base_url: '/', lotus_head: false, database: 'filesystem']
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
        content.must_match %(gem 'lotusrb',       '#{ Lotus::VERSION }')
        content.must_match %(gem 'lotus-model',   '~> 0.4')
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
          content.must_match %(gem 'lotus-helpers',     require: false, github: 'lotus/helpers')
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

      describe 'database option' do
        describe 'mysql' do
          let(:opts) { container_options.merge(database: 'mysql') }
          it 'includes mysql' do
            content = @root.join('Gemfile').read
            content.must_match %(gem 'mysql')
          end
        end

        describe 'mysql2' do
          let(:opts) { container_options.merge(database: 'mysql2') }
          it 'includes mysql2' do
            content = @root.join('Gemfile').read
            content.must_match %(gem 'mysql2')
          end
        end

        describe 'postgresql' do
          let(:opts) { container_options.merge(database: 'postgresql') }

          it 'includes pg' do
            content = @root.join('Gemfile').read
            content.must_match %(gem 'pg')
          end
        end

        describe 'postgres' do
          let(:opts) { container_options.merge(database: 'postgres') }

          it 'includes pg' do
            content = @root.join('Gemfile').read
            content.must_match %(gem 'pg')
          end
        end

        describe 'sqlite' do
          let(:opts) { container_options.merge(database: 'sqlite') }

          it 'includes sqlite3 gem' do
            content = @root.join('Gemfile').read
            content.must_match %(gem 'sqlite3')
          end
        end

        describe 'sqlite3' do
          let(:opts) { container_options.merge(database: 'sqlite3') }

          it 'includes sqlite3 gem' do
            content = @root.join('Gemfile').read
            content.must_match %(gem 'sqlite3')
          end
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

    describe '.lotusrc' do
      describe 'minitest (default)' do
        it 'generates it' do
          content = @root.join('.lotusrc').read
          content.must_match %(architecture=container)
          content.must_match %(test=minitest)
          content.must_match %(template=erb)
        end
      end

      describe 'rspec' do
        let(:opts) { container_options.merge(test: 'rspec') }

        it 'generates it' do
          content = @root.join('.lotusrc').read
          content.must_match %(test=rspec)
        end
      end
    end

    describe '.gitignore' do
      it 'generates it' do
        content = @root.join('.gitignore').read
        content.must_match %(/db/chirp_development)
        content.must_match %(/db/chirp_test)
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

    describe '.env' do
      it 'generates it' do
        content = @root.join('.env').read
        content.must_match %(# Define ENV variables)
      end
    end

    describe '.env.development' do
      it 'generates it' do
        content = @root.join('.env.development').read
        content.must_match %(# Define ENV variables for development environment)
        content.must_match %(CHIRP_DATABASE_URL="file:///db/chirp_development")
      end

      describe "with non-simple application name" do
        let(:app_name) { "chirp-two" }

        it "sanitizes application names for env variables" do
          content = @root.join('.env.development').read
          content.must_match %(CHIRP_TWO_DATABASE_URL="file:///db/chirp-two_development")
        end
      end

      describe 'database option' do
        describe 'with mysql' do
          let(:opts) { container_options.merge(database: 'mysql') }

          it 'generates db config for mysql' do
            content = @root.join('.env.development').read
            content.must_match %(CHIRP_DATABASE_URL="mysql://localhost/chirp_development")
          end
        end

        describe 'with mysql2' do
          let(:opts) { container_options.merge(database: 'mysql2') }

          it 'generates db config for mysql2' do
            content = @root.join('.env.development').read
            content.must_match %(CHIRP_DATABASE_URL="mysql2://localhost/chirp_development")
          end
        end

        describe 'with postgresql' do
          let(:opts) { container_options.merge(database: 'postgresql') }

          it 'generates db config for postgresql' do
            content = @root.join('.env.development').read
            content.must_match %(CHIRP_DATABASE_URL="postgres://localhost/chirp_development")
          end
        end

        describe 'with postgres' do
          let(:opts) { container_options.merge(database: 'postgres') }

          it 'generates db config for postgres' do
            content = @root.join('.env.development').read
            content.must_match %(CHIRP_DATABASE_URL="postgres://localhost/chirp_development")
          end
        end

        describe 'with sqlite' do
          let(:opts) { container_options.merge(database: 'sqlite') }

          it 'generates db config for sqlite' do
            content = @root.join('.env.development').read
            content.must_match %(CHIRP_DATABASE_URL="sqlite://db/chirp_development.sqlite")
          end

          describe 'with non-simple application name' do
            let(:app_name) { "chirp'two" }

            it 'escapes the database url' do
              content = @root.join('.env.development').read
              content.must_match %(CHIRP_TWO_DATABASE_URL="sqlite://db/chirp\\'two_development.sqlite")
            end
          end
        end

        describe 'with sqlite3' do
          let(:opts) { container_options.merge(database: 'sqlite3') }
          it 'generates db config for sqlite3' do
            content = @root.join('.env.development').read
            content.must_match %(CHIRP_DATABASE_URL="sqlite://db/chirp_development.sqlite")
          end

          describe 'with non-simple application name' do
            let(:app_name) { "chirp'two" }

            it 'escapes the database url' do
              content = @root.join('.env.development').read
              content.must_match %(CHIRP_TWO_DATABASE_URL="sqlite://db/chirp\\'two_development.sqlite")
            end
          end
        end

        describe 'with memory' do
          let(:opts) { container_options.merge(database: 'memory') }

          it 'generates db config for memory' do
            content = @root.join('.env.development').read
            content.must_match %(CHIRP_DATABASE_URL="memory://localhost/chirp_development")
          end
        end
      end
    end

    describe '.env.test' do
      it 'generates it' do
        content = @root.join('.env.test').read
        content.must_match %(# Define ENV variables for test environment)
        content.must_match %(CHIRP_DATABASE_URL="file:///db/chirp_test")
      end

      describe "with non-simple application name" do
        let(:app_name) { "chirp-two" }

        it "sanitizes application names for env variables" do
          content = @root.join('.env.test').read
          content.must_match %(CHIRP_TWO_DATABASE_URL="file:///db/chirp-two_test")
        end
      end

      describe 'database option' do
        describe 'with mysql' do
          let(:opts) { container_options.merge(database: 'mysql') }
          it 'generates db config for mysql' do
            content = @root.join('.env.test').read
            content.must_match %(CHIRP_DATABASE_URL="mysql://localhost/chirp_test")
          end
        end

        describe 'with mysql2' do
          let(:opts) { container_options.merge(database: 'mysql2') }
          it 'generates db config for mysql2' do
            content = @root.join('.env.test').read
            content.must_match %(CHIRP_DATABASE_URL="mysql2://localhost/chirp_test")
          end
        end

        describe 'with postgresql' do
          let(:opts) { container_options.merge(database: 'postgresql') }

          it 'generates db config for postgresql' do
            content = @root.join('.env.test').read
            content.must_match %(CHIRP_DATABASE_URL="postgres://localhost/chirp_test")
          end
        end

        describe 'with postgres' do
          let(:opts) { container_options.merge(database: 'postgres') }

          it 'generates db config for postgres' do
            content = @root.join('.env.test').read
            content.must_match %(CHIRP_DATABASE_URL="postgres://localhost/chirp_test")
          end
        end

        describe 'with sqlite' do
          let(:opts) { container_options.merge(database: 'sqlite') }

          it 'generates db config for sqlite' do
            content = @root.join('.env.test').read
            content.must_match %(CHIRP_DATABASE_URL="sqlite://db/chirp_test.sqlite")
          end

          describe 'with non-simple application name' do
            let(:app_name) { "chirp'two" }

            it 'escapes the database url' do
              content = @root.join('.env.test').read
              content.must_match %(CHIRP_TWO_DATABASE_URL="sqlite://db/chirp\\'two_test.sqlite")
            end
          end
        end

        describe 'with sqlite3' do
          let(:opts) { container_options.merge(database: 'sqlite3') }
          it 'generates db config for sqlite3' do
            content = @root.join('.env.test').read
            content.must_match %(CHIRP_DATABASE_URL="sqlite://db/chirp_test.sqlite")
          end

          describe 'with non-simple application name' do
            let(:app_name) { "chirp'two" }
            it 'escapes the database url' do
              content = @root.join('.env.test').read
              content.must_match %(CHIRP_TWO_DATABASE_URL="sqlite://db/chirp\\'two_test.sqlite")
            end
          end
        end

        describe 'with memory' do
          let(:opts) { container_options.merge(database: 'memory') }
          it 'generates db config for memory' do
            content = @root.join('.env.test').read
            content.must_match %(CHIRP_DATABASE_URL="memory://localhost/chirp_test")
          end
        end
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
        content.must_match %(mapping "\#{__dir__}/config/mapping")
      end

      describe "with non-simple application name" do
        let(:app_name) { "chirp-two" }

        it "sanitizes application names for env variables" do
          content = @root.join('lib/chirp-two.rb').read
          content.must_match 'Dir["#{ __dir__ }/chirp-two/**/*.rb"].each { |file| require_relative file }'
          content.must_match %(adapter type: :file_system, uri: ENV['CHIRP_TWO_DATABASE_URL'])
        end
      end

      describe 'database option' do
        describe 'mysql' do
          let(:opts) { container_options.merge(database: 'mysql') }
          it 'generates adapter config for mysql' do
            content = @root.join('lib/chirp.rb').read
            content.must_match %(adapter type: :sql, uri: ENV['CHIRP_DATABASE_URL'])
            content.must_match %(migrations 'db/migrations')
            content.must_match %(schema     'db/schema.sql')
          end
        end

        describe 'mysql2' do
          let(:opts) { container_options.merge(database: 'mysql2') }
          it 'generates adapter config for mysql2' do
            content = @root.join('lib/chirp.rb').read
            content.must_match %(adapter type: :sql, uri: ENV['CHIRP_DATABASE_URL'])
            content.must_match %(migrations 'db/migrations')
            content.must_match %(schema     'db/schema.sql')
          end
        end

        describe 'postgresql' do
          let(:opts) { container_options.merge(database: 'postgresql') }
          it 'generates adapter config for postgresql' do
            content = @root.join('lib/chirp.rb').read
            content.must_match %(adapter type: :sql, uri: ENV['CHIRP_DATABASE_URL'])
            content.must_match %(migrations 'db/migrations')
            content.must_match %(schema     'db/schema.sql')
          end
        end

        describe 'postgres' do
          let(:opts) { container_options.merge(database: 'postgres') }

          it 'generates adapter config for postgres' do
            content = @root.join('lib/chirp.rb').read
            content.must_match %(adapter type: :sql, uri: ENV['CHIRP_DATABASE_URL'])
            content.must_match %(migrations 'db/migrations')
            content.must_match %(schema     'db/schema.sql')
          end
        end

        describe 'sqlite' do
          let(:opts) { container_options.merge(database: 'sqlite') }

          it 'generates adapter config for sqlite' do
            content = @root.join('lib/chirp.rb').read
            content.must_match %(adapter type: :sql, uri: ENV['CHIRP_DATABASE_URL'])
            content.must_match %(migrations 'db/migrations')
            content.must_match %(schema     'db/schema.sql')
          end
        end

        describe 'sqlite3' do
          let(:opts) { container_options.merge(database: 'sqlite3') }
          it 'generates adapter config for sqlite3' do
            content = @root.join('lib/chirp.rb').read
            content.must_match %(adapter type: :sql, uri: ENV['CHIRP_DATABASE_URL'])
            content.must_match %(migrations 'db/migrations')
            content.must_match %(schema     'db/schema.sql')
          end
        end

        describe 'memory' do
          let(:opts) { container_options.merge(database: 'memory') }
          it 'generates adapter config for memory' do
            content = @root.join('lib/chirp.rb').read
            content.must_match %(adapter type: :memory, uri: ENV['CHIRP_DATABASE_URL'])
            content.wont_match %(migrations 'db/migrations')
            content.wont_match %(schema     'db/schema.sql')
          end
        end
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
        @root.join('db').must_be            :directory?
        @root.join('db/migrations').wont_be :exist?
      end

      ['postgres', 'postgresql', 'mysql', 'mysql2', 'sqlite', 'sqlite3'].each do |database|
        describe "with #{ database }" do
          let(:opts) { container_options.merge(database: database) }

          it "generates 'db/migrations'" do
            @root.join('db/migrations').must_be          :directory?
            @root.join('db/migrations/.gitkeep').must_be :exist?

            @root.join('db/.gitkeep').wont_be :exist?
          end

          it "generates empty 'db/schema.sql'" do
            @root.join('db/schema.sql').must_be      :exist?
            @root.join('db/schema.sql').read.must_be :empty?
          end
        end
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
              content.must_match %(Lotus::Application.preload!)
              content.must_match %(RSpec.configure do |config|)
              content.must_match %(config.filter_run :focus)
              content.must_match %(config.run_all_when_everything_filtered = true)

              content.must_match %(if config.files_to_run.one?)
              content.must_match %(config.default_formatter = 'doc')

              content.must_match %(config.order = :random)
              content.must_match %(Kernel.srand config.seed)

              content.must_match %(config.expect_with :rspec do |expectations|)

              content.must_match %(config.mock_with :rspec do |mocks|)
              content.must_match %(mocks.verify_partial_doubles = true)
            end
          end
        end

        describe '.rspec' do
          let(:opts) { container_options.merge(test: 'rspec') }

          it 'generates it' do
            content = @root.join('.rspec').read
            content.must_match %(--color)
            content.must_match %(--require spec_helper)
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

    describe '.env.development' do
      it 'patches the file to reference slice env vars' do
        content = @root.join('.env.development').read
        content.wont_match %(WEB_DATABASE_URL="file:///db/web_development")
        content.must_match %r{WEB_SESSIONS_SECRET="[\w]{64}"}
      end
    end

    describe '.env.test' do
      it 'patches the file to reference slice env vars' do
        content = @root.join('.env.test').read
        content.wont_match %(WEB_DATABASE_URL="file:///db/web_test")
        content.must_match %r{WEB_SESSIONS_SECRET="[\w]{64}"}
      end
    end

    describe 'apps/web/application.rb' do
      it 'generates it' do
        content = @root.join('apps/web/application.rb').read
        content.must_match %(require 'lotus/helpers')
        content.must_match %(module Web)
        content.must_match %(class Application < Lotus::Application)

        # main configure block
        content.must_match %(configure do)
        content.must_match %(root __dir__)

        content.must_match %(routes 'config/routes')

        content.must_match %(layout :application)
        content.must_match %(templates 'templates')

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

        # security
        content.must_match %(security.x_frame_options "DENY")
        content.must_match %(security.content_security_policy "default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self'; style-src 'self';")

        content.must_match %(controller.prepare)
        content.must_match %(view.prepare)
        content.must_match %(include Lotus::Helpers)

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
      end
    end

    describe 'apps/web/controllers' do
      it 'generates it' do
        @root.join('apps/web/controllers').must_be :exist?
      end
    end

    describe 'apps/web/views' do
      it 'generates it' do
        @root.join('apps/web/views').must_be :exist?
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
  end

  describe 'application architecture' do
    def container_options
      Hash[architecture: architecture, application: 'web', application_base_url: '/', lotus_head: false, database: 'filesystem']
    end

    let(:opts)     { container_options }
    let(:app_name) { 'chirp' }
    let(:architecture) { 'app' }

    before do
      capture_io { command.start }
    end

    describe 'Gemfile' do
      it 'generates it' do
        content = @root.join('Gemfile').read
        content.must_match %(gem 'bundler')
        content.must_match %(gem 'rake')
        content.must_match %(gem 'lotusrb',       '#{ Lotus::VERSION }')
        content.must_match %(gem 'lotus-model',   '~> 0.4')
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
          content.must_match %(gem 'lotus-helpers',     require: false, github: 'lotus/helpers')
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

      describe 'database option' do
        describe 'mysql' do
          let(:opts) { container_options.merge(database: 'mysql') }
          it 'includes mysql' do
            content = @root.join('Gemfile').read
            content.must_match %(gem 'mysql')
          end
        end

        describe 'mysql2' do
          let(:opts) { container_options.merge(database: 'mysql2') }
          it 'includes mysql2' do
            content = @root.join('Gemfile').read
            content.must_match %(gem 'mysql2')
          end
        end

        describe 'postgresql' do
          let(:opts) { container_options.merge(database: 'postgresql') }

          it 'includes pg' do
            content = @root.join('Gemfile').read
            content.must_match %(gem 'pg')
          end
        end

        describe 'postgres' do
          let(:opts) { container_options.merge(database: 'postgres') }

          it 'includes pg' do
            content = @root.join('Gemfile').read
            content.must_match %(gem 'pg')
          end
        end

        describe 'sqlite' do
          let(:opts) { container_options.merge(database: 'sqlite') }

          it 'includes sqlite3 gem' do
            content = @root.join('Gemfile').read
            content.must_match %(gem 'sqlite3')
          end
        end

        describe 'sqlite3' do
          let(:opts) { container_options.merge(database: 'sqlite3') }

          it 'includes sqlite3 gem' do
            content = @root.join('Gemfile').read
            content.must_match %(gem 'sqlite3')
          end
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
        content.must_match %(run Chirp::Application.new)
      end
    end

    describe '.lotusrc' do
      describe 'minitest (default)' do
        it 'generates it' do
          content = @root.join('.lotusrc').read
          content.must_match %(architecture=app)
          content.must_match %(test=minitest)
          content.must_match %(template=erb)
        end
      end

      describe 'rspec' do
        let(:opts) { container_options.merge(test: 'rspec') }

        it 'generates it' do
          content = @root.join('.lotusrc').read
          content.must_match %(test=rspec)
        end
      end
    end

    describe '.gitignore' do
      it 'generates it' do
        content = @root.join('.gitignore').read
        content.must_match %(/db/chirp_development)
        content.must_match %(/db/chirp_test)
      end
    end

    describe 'config/environment.rb' do
      it 'generates it' do
        content = @root.join('config/environment.rb').read
        content.must_match %(require 'rubygems')
        content.must_match %(require 'bundler/setup')
        content.must_match %(require 'lotus/setup')
        content.must_match %(require_relative '../lib/chirp')
        content.must_match %(require_relative '../config/application')
      end
    end

    describe '.env' do
      it 'generates it' do
        content = @root.join('.env').read
        content.must_match %(# Define ENV variables)
      end
    end

    describe '.env.development' do
      it 'generates it' do
        content = @root.join('.env.development').read
        content.must_match %(# Define ENV variables for development environment)
        content.must_match %(CHIRP_DATABASE_URL="file:///db/chirp_development")
        content.wont_match %(CHIRP_SESSIONS_SECRET="")
        content.must_match %(CHIRP_SESSIONS_SECRET=)
      end

      describe "with non-simple application name" do
        let(:app_name) { "chirp-two" }

        it "sanitizes application names for env variables" do
          content = @root.join('.env.development').read
          content.must_match %(CHIRP_TWO_DATABASE_URL="file:///db/chirp-two_development")
        end
      end

      describe 'database option' do
        describe 'with mysql' do
          let(:opts) { container_options.merge(database: 'mysql') }

          it 'generates db config for mysql' do
            content = @root.join('.env.development').read
            content.must_match %(CHIRP_DATABASE_URL="mysql://localhost/chirp_development")
          end
        end

        describe 'with mysql2' do
          let(:opts) { container_options.merge(database: 'mysql2') }

          it 'generates db config for mysql2' do
            content = @root.join('.env.development').read
            content.must_match %(CHIRP_DATABASE_URL="mysql2://localhost/chirp_development")
          end
        end

        describe 'with postgresql' do
          let(:opts) { container_options.merge(database: 'postgresql') }

          it 'generates db config for postgresql' do
            content = @root.join('.env.development').read
            content.must_match %(CHIRP_DATABASE_URL="postgres://localhost/chirp_development")
          end
        end

        describe 'with postgres' do
          let(:opts) { container_options.merge(database: 'postgres') }

          it 'generates db config for postgres' do
            content = @root.join('.env.development').read
            content.must_match %(CHIRP_DATABASE_URL="postgres://localhost/chirp_development")
          end
        end

        describe 'with sqlite' do
          let(:opts) { container_options.merge(database: 'sqlite') }

          it 'generates db config for sqlite' do
            content = @root.join('.env.development').read
            content.must_match %(CHIRP_DATABASE_URL="sqlite://db/chirp_development")
          end

          describe 'with non-simple application name' do
            let(:app_name) { "chirp'two" }

            it 'escapes the database url' do
              content = @root.join('.env.development').read
              content.must_match %(CHIRP_TWO_DATABASE_URL="sqlite://db/chirp\\'two_development")
            end
          end
        end

        describe 'with sqlite3' do
          let(:opts) { container_options.merge(database: 'sqlite3') }
          it 'generates db config for sqlite3' do
            content = @root.join('.env.development').read
            content.must_match %(CHIRP_DATABASE_URL="sqlite://db/chirp_development")
          end

          describe 'with non-simple application name' do
            let(:app_name) { "chirp'two" }

            it 'escapes the database url' do
              content = @root.join('.env.development').read
              content.must_match %(CHIRP_TWO_DATABASE_URL="sqlite://db/chirp\\'two_development")
            end
          end
        end

        describe 'with memory' do
          let(:opts) { container_options.merge(database: 'memory') }

          it 'generates db config for memory' do
            content = @root.join('.env.development').read
            content.must_match %(CHIRP_DATABASE_URL="memory://localhost/chirp_development")
          end
        end
      end
    end

    describe '.env.test' do
      it 'generates it' do
        content = @root.join('.env.test').read
        content.must_match %(# Define ENV variables for test environment)
        content.must_match %(CHIRP_DATABASE_URL="file:///db/chirp_test")
        content.wont_match %(CHIRP_SESSIONS_SECRET="")
        content.must_match %(CHIRP_SESSIONS_SECRET=)
      end

      describe "with non-simple application name" do
        let(:app_name) { "chirp-two" }

        it "sanitizes application names for env variables" do
          content = @root.join('.env.test').read
          content.must_match %(CHIRP_TWO_DATABASE_URL="file:///db/chirp-two_test")
        end
      end

      describe 'database option' do
        describe 'with mysql' do
          let(:opts) { container_options.merge(database: 'mysql') }
          it 'generates db config for mysql' do
            content = @root.join('.env.test').read
            content.must_match %(CHIRP_DATABASE_URL="mysql://localhost/chirp_test")
          end
        end

        describe 'with mysql2' do
          let(:opts) { container_options.merge(database: 'mysql2') }
          it 'generates db config for mysql2' do
            content = @root.join('.env.test').read
            content.must_match %(CHIRP_DATABASE_URL="mysql2://localhost/chirp_test")
          end
        end

        describe 'with postgresql' do
          let(:opts) { container_options.merge(database: 'postgresql') }

          it 'generates db config for postgresql' do
            content = @root.join('.env.test').read
            content.must_match %(CHIRP_DATABASE_URL="postgres://localhost/chirp_test")
          end
        end

        describe 'with postgres' do
          let(:opts) { container_options.merge(database: 'postgres') }

          it 'generates db config for postgres' do
            content = @root.join('.env.test').read
            content.must_match %(CHIRP_DATABASE_URL="postgres://localhost/chirp_test")
          end
        end

        describe 'with sqlite' do
          let(:opts) { container_options.merge(database: 'sqlite') }

          it 'generates db config for sqlite' do
            content = @root.join('.env.test').read
            content.must_match %(CHIRP_DATABASE_URL="sqlite://db/chirp_test")
          end

          describe 'with non-simple application name' do
            let(:app_name) { "chirp'two" }

            it 'escapes the database url' do
              content = @root.join('.env.test').read
              content.must_match %(CHIRP_TWO_DATABASE_URL="sqlite://db/chirp\\'two_test")
            end
          end
        end

        describe 'with sqlite3' do
          let(:opts) { container_options.merge(database: 'sqlite3') }
          it 'generates db config for sqlite3' do
            content = @root.join('.env.test').read
            content.must_match %(CHIRP_DATABASE_URL="sqlite://db/chirp_test")
          end

          describe 'with non-simple application name' do
            let(:app_name) { "chirp'two" }
            it 'escapes the database url' do
              content = @root.join('.env.test').read
              content.must_match %(CHIRP_TWO_DATABASE_URL="sqlite://db/chirp\\'two_test")
            end
          end
        end

        describe 'with memory' do
          let(:opts) { container_options.merge(database: 'memory') }
          it 'generates db config for memory' do
            content = @root.join('.env.test').read
            content.must_match %(CHIRP_DATABASE_URL="memory://localhost/chirp_test")
          end
        end
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
        content.must_match %(mapping "\#{__dir__}/config/mapping")
      end

      describe "with non-simple application name" do
        let(:app_name) { "chirp-two" }

        it "sanitizes application names for env variables" do
          content = @root.join('lib/chirp-two.rb').read
          content.must_match 'Dir["#{ __dir__ }/chirp-two/**/*.rb"].each { |file| require_relative file }'
          content.must_match %(adapter type: :file_system, uri: ENV['CHIRP_TWO_DATABASE_URL'])
        end
      end

      describe 'database option' do
        describe 'mysql' do
          let(:opts) { container_options.merge(database: 'mysql') }
          it 'generates adapter config for mysql' do
            content = @root.join('lib/chirp.rb').read
            content.must_match %(adapter type: :sql, uri: ENV['CHIRP_DATABASE_URL'])
            content.must_match %(migrations 'db/migrations')
            content.must_match %(schema     'db/schema.sql')
          end
        end

        describe 'mysql2' do
          let(:opts) { container_options.merge(database: 'mysql2') }
          it 'generates adapter config for mysql2' do
            content = @root.join('lib/chirp.rb').read
            content.must_match %(adapter type: :sql, uri: ENV['CHIRP_DATABASE_URL'])
            content.must_match %(migrations 'db/migrations')
            content.must_match %(schema     'db/schema.sql')
          end
        end

        describe 'postgresql' do
          let(:opts) { container_options.merge(database: 'postgresql') }
          it 'generates adapter config for postgresql' do
            content = @root.join('lib/chirp.rb').read
            content.must_match %(adapter type: :sql, uri: ENV['CHIRP_DATABASE_URL'])
            content.must_match %(migrations 'db/migrations')
            content.must_match %(schema     'db/schema.sql')
          end
        end

        describe 'postgres' do
          let(:opts) { container_options.merge(database: 'postgres') }

          it 'generates adapter config for postgres' do
            content = @root.join('lib/chirp.rb').read
            content.must_match %(adapter type: :sql, uri: ENV['CHIRP_DATABASE_URL'])
            content.must_match %(migrations 'db/migrations')
            content.must_match %(schema     'db/schema.sql')
          end
        end

        describe 'sqlite' do
          let(:opts) { container_options.merge(database: 'sqlite') }

          it 'generates adapter config for sqlite' do
            content = @root.join('lib/chirp.rb').read
            content.must_match %(adapter type: :sql, uri: ENV['CHIRP_DATABASE_URL'])
            content.must_match %(migrations 'db/migrations')
            content.must_match %(schema     'db/schema.sql')
          end
        end

        describe 'sqlite3' do
          let(:opts) { container_options.merge(database: 'sqlite3') }
          it 'generates adapter config for sqlite3' do
            content = @root.join('lib/chirp.rb').read
            content.must_match %(adapter type: :sql, uri: ENV['CHIRP_DATABASE_URL'])
            content.must_match %(migrations 'db/migrations')
            content.must_match %(schema     'db/schema.sql')
          end
        end

        describe 'memory' do
          let(:opts) { container_options.merge(database: 'memory') }
          it 'generates adapter config for memory' do
            content = @root.join('lib/chirp.rb').read
            content.must_match %(adapter type: :memory, uri: ENV['CHIRP_DATABASE_URL'])
          end
        end
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
        @root.join('db').must_be            :directory?
        @root.join('db/migrations').wont_be :exist?
      end

      ['postgres', 'postgresql', 'mysql', 'mysql2', 'sqlite', 'sqlite3'].each do |database|
        describe "with #{ database }" do
          let(:opts) { container_options.merge(database: database) }

          it "generates 'db/migrations'" do
            @root.join('db/migrations').must_be          :directory?
            @root.join('db/migrations/.gitkeep').must_be :exist?

            @root.join('db/.gitkeep').wont_be :exist?
          end

          it "generates empty 'db/schema.sql'" do
            @root.join('db/schema.sql').must_be      :exist?
            @root.join('db/schema.sql').read.must_be :empty?
          end
        end
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
              content.must_match %(Lotus::Application.preload!)
              content.must_match %(RSpec.configure do |config|)
              content.must_match %(config.filter_run :focus)
              content.must_match %(config.run_all_when_everything_filtered = true)

              content.must_match %(if config.files_to_run.one?)
              content.must_match %(config.default_formatter = 'doc')

              content.must_match %(config.order = :random)
              content.must_match %(Kernel.srand config.seed)

              content.must_match %(config.expect_with :rspec do |expectations|)

              content.must_match %(config.mock_with :rspec do |mocks|)
              content.must_match %(mocks.verify_partial_doubles = true)
            end
          end
        end

        describe '.rspec' do
          let(:opts) { container_options.merge(test: 'rspec') }

          it 'generates it' do
            content = @root.join('.rspec').read
            content.must_match %(--color)
            content.must_match %(--require spec_helper)
          end
        end

        describe 'spec/features_helper.rb' do
          describe 'minitest (default)' do
            it 'generates it' do
              content = @root.join('spec/features_helper.rb').read
              content.must_match %(require_relative './spec_helper')
              content.must_match %(require 'capybara')
              content.must_match %(require 'capybara/dsl')
              content.must_match %(Capybara.app = Chirp::Application.new)
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
              content.must_match %(Capybara.app = Chirp::Application.new)
            end
          end
        end
      end
    end

    ################
    # SLICE
    ################

    describe 'config/application.rb' do
      it 'generates it' do
        content = @root.join('config/application.rb').read
        content.must_match %(require 'lotus/helpers')
        content.must_match %(module Chirp)
        content.must_match %(class Application < Lotus::Application)

        # main configure block
        content.must_match %(configure do)
        content.must_match 'root "#{ __dir__ }/.."'

        content.must_match %(routes 'config/routes')

        content.must_match %(layout :application)
        content.must_match %(templates 'app/templates')

        content.must_match %(# cookies true)

        content.must_match %(# sessions :cookie, secret: ENV['CHIRP_SESSIONS_SECRET'])

        content.must_match %(load_paths << [)
        content.must_match %('app/controllers')
        content.must_match %('app/views')

        content.must_match %(# middleware.use Rack::Protection)

        content.must_match %(# body_parsers :json)

        content.must_match %(# assets << [)
        content.must_match %(#   'vendor/javascripts')

        content.must_match %(# serve_assets false)

        # security
        content.must_match %(security.x_frame_options "DENY")
        content.must_match %(security.content_security_policy "default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self'; style-src 'self';")

        content.must_match %(controller.prepare)
        content.must_match %(view.prepare)
        content.must_match %(include Lotus::Helpers)

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

    describe 'config/routes.rb' do
      it 'generates it' do
        content = @root.join('config/routes.rb').read
        content.must_match %(# Configure your routes here)
      end
    end

    describe 'app/controllers' do
      it 'generates it' do
        @root.join('app/controllers').must_be :exist?
      end
    end

    describe 'app/views' do
      it 'generates it' do
        @root.join('app/views').must_be :exist?
      end
    end

    describe 'app/views/application_layout.rb' do
      it 'generates it' do
        content = @root.join('app/views/application_layout.rb').read
        content.must_match %(module Chirp)
        content.must_match %(module Views)
        content.must_match %(class ApplicationLayout)
        content.must_match %(include Chirp::Layout)
      end
    end

    describe 'app/templates/application.html.rb' do
      it 'generates it' do
        content = @root.join('app/templates/application.html.erb').read
        content.must_match %(<title>Chirp</title>)
        content.must_match %(<%= yield %>)
      end
    end

    describe 'public/javascripts' do
      it 'generates it' do
        @root.join('public/javascripts').must_be :exist?
      end
    end

    describe 'public/stylesheets' do
      it 'generates it' do
        @root.join('public/stylesheets').must_be :exist?
      end
    end

    describe 'testing' do
      describe 'when minitest (default)' do
        describe 'spec/features' do
          it 'generates it' do
            @root.join('spec/features').must_be :directory?
          end
        end

        describe 'spec/controllers' do
          it 'generates it' do
            @root.join('spec/controllers').must_be :directory?
          end
        end

        describe 'spec/views' do
          it 'generates it' do
            @root.join('spec/views').must_be :directory?
          end
        end
      end
    end
  end

  describe 'when app_name is .' do
    def container_options
      Hash[architecture: architecture, application: 'web', application_base_url: '/', lotus_head: false, database: 'filesystem']
    end

    def clear_root_folder
      FileUtils.rm_rf("#{@root}/.", secure: true)
    end

    let(:opts)      { container_options }
    let(:app_name)  { '.' }

    before do
      clear_root_folder
      capture_io { command.start }
    end

    describe 'when architecture is container' do
      let(:architecture) { 'container' }

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

      describe '.env.development' do
        it 'generates it' do
          content = @root.join('.env.development').read
          content.must_match %(NEW_DATABASE_URL="file:///db/new_development")
        end
      end

      describe '.env.test' do
        it 'generates it' do
          content = @root.join('.env.test').read
          content.must_match %(NEW_DATABASE_URL="file:///db/new_test")
        end
      end
    end

    describe 'when architecture is application' do
      let(:architecture) { 'app' }

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

      describe '.env.development' do
        it 'generates it' do
          content = @root.join('.env.development').read
          content.must_match %(NEW_DATABASE_URL="file:///db/new_development")
        end
      end

      describe '.env.test' do
        it 'generates it' do
          content = @root.join('.env.test').read
          content.must_match %(NEW_DATABASE_URL="file:///db/new_test")
        end
      end
    end
  end

  describe 'application path' do
    def container_options
      Hash[architecture: architecture, application: 'web', application_base_url: '/', lotus_head: false, database: 'filesystem']
    end

    let(:opts)      { container_options }
    let(:app_name)  { 'chirp' }

    before do
      capture_io { command.start }
    end

    describe 'when a path is provided' do
      let(:opts) { container_options.merge(path: 'my_lotus_app') }

      it 'generates the app at the specific path' do
        @root.dirname().join('my_lotus_app').must_be :directory?
      end
    end
  end

  describe 'when a path is provided as the app name' do
    let(:opts)      { Hash[architecture: architecture, application: 'web', application_base_url: '/', lotus_head: false] }
    let(:app_name)  { 'lib/chirp' }

    it 'raises an ArgumentError' do
      exception = -> { command.start }.must_raise ArgumentError
      exception.message.must_equal 'Invalid application name. If you want to set application path, please use --path option'
    end
  end
end
