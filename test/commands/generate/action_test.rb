require 'test_helper'
require 'lotus/commands/generate/action'
require 'fileutils'

describe Lotus::Commands::Generate::Action do
  describe 'with invalid arguments' do
    it 'requires application name' do
      with_temp_dir do |original_wd|
        setup_container_app
        -> { Lotus::Commands::Generate::Action.new({}, nil, 'books#index') }.must_raise ArgumentError
        -> { Lotus::Commands::Generate::Action.new({}, '', 'books#index') }.must_raise ArgumentError
        -> { Lotus::Commands::Generate::Action.new({}, '  ', 'books#index') }.must_raise ArgumentError
      end
    end

    it 'requires controller and action name' do
      with_temp_dir do |previus_wd|
        setup_container_app
        -> { Lotus::Commands::Generate::Action.new({}, 'web', 'books') }.must_raise ArgumentError
        -> { Lotus::Commands::Generate::Action.new({}, 'web', '') }.must_raise ArgumentError
        -> { Lotus::Commands::Generate::Action.new({}, 'web', ' ') }.must_raise ArgumentError
      end
    end

    it 'verifies the method option' do
      with_temp_dir do |previus_wd|
        setup_container_app
        -> { Lotus::Commands::Generate::Action.new({method: 'UnKnOwN'}, 'web', 'books#action') }.must_raise ArgumentError
      end
    end
  end

  describe 'with valid arguments' do
    it 'uses --template option as extension for the template' do
      with_temp_dir do |original_wd|
        setup_container_app
        command = Lotus::Commands::Generate::Action.new({template: 'haml'}, 'web', 'books#index')
        capture_io { command.start }
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/template.html.haml'), 'apps/web/templates/books/index.html.haml')
      end
    end

    describe 'route options' do
      it 'uses the --method option to specify HTTP method in the route' do
        with_temp_dir do |original_wd|
          setup_container_app
          Lotus::Routing::Route::VALID_HTTP_VERBS.each do |m|
            command = Lotus::Commands::Generate::Action.new({method: m}, 'web', 'books#index')
            capture_io { command.start }

            expected = "#{m.downcase} '/books', to: 'books#index'"
            actual = File.read('apps/web/config/routes.rb')
            assert actual.include?(expected)
          end
        end
      end

      it 'uses the --url option to specify the route url' do
        with_temp_dir do |original_wd|
          setup_container_app
          command = Lotus::Commands::Generate::Action.new({url: '/mybooks'}, 'web', 'books#index')
          capture_io { command.start }

          expected = "get '/mybooks', to: 'books#index'"
          actual = File.read('apps/web/config/routes.rb')
          assert actual.include?(expected)
        end
      end
    end

    describe 'container architecture' do
      describe 'with minitest' do
        it 'generates the files' do
          with_temp_dir do |original_wd|
            setup_container_app

            command = Lotus::Commands::Generate::Action.new({}, 'web', 'books#index')
            capture_io { command.start }

            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/routes.get.rb'), 'apps/web/config/routes.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action_spec.container.minitest.rb'), 'spec/web/controllers/books/index_spec.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action.container.rb'), 'apps/web/controllers/books/index.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/view.container.rb'), 'apps/web/views/books/index.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/template.html.erb'), 'apps/web/templates/books/index.html.erb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/view_spec.container.minitest.rb'), 'spec/web/views/books/index_spec.rb')
          end
        end

        it 'skips the view' do
          with_temp_dir do |original_wd|
            setup_container_app

            command = Lotus::Commands::Generate::Action.new({skip_view: true}, 'web', 'books#index')
            capture_io { command.start }

            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/routes.get.rb'), 'apps/web/config/routes.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action_spec.container.minitest.rb'), 'spec/web/controllers/books/index_spec.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action_without_view.container.rb'), 'apps/web/controllers/books/index.rb')

            refute File.exist?('apps/web/views/books/index.rb')
            refute File.exist?('apps/web/templates/books/index.html.erb')
            refute File.exist?('spec/web/views/books/index_spec.rb')
          end
        end
      end

      describe 'with rspec' do
        it 'generates the files' do
          with_temp_dir do |original_wd|
            setup_container_app

            command = Lotus::Commands::Generate::Action.new({test: 'rspec'}, 'web', 'books#index')
            capture_io { command.start }

            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/routes.get.rb'), 'apps/web/config/routes.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action_spec.container.rspec.rb'), 'spec/web/controllers/books/index_spec.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action.container.rb'), 'apps/web/controllers/books/index.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/view.container.rb'), 'apps/web/views/books/index.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/template.html.erb'), 'apps/web/templates/books/index.html.erb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/view_spec.container.rspec.rb'), 'spec/web/views/books/index_spec.rb')
          end
        end
      end
    end

    describe 'app architecture' do
      describe 'with minitest' do
        it 'generates the files' do
          with_temp_dir do |original_wd|
            setup_app_app

            command = Lotus::Commands::Generate::Action.new({}, 'testapp', 'books#index')
            capture_io { command.start }

            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/routes.get.rb'), 'config/routes.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action_spec.app.minitest.rb'), 'spec/controllers/books/index_spec.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action.app.rb'), 'app/controllers/books/index.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/view.app.rb'), 'app/views/books/index.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/template.html.erb'), 'app/templates/books/index.html.erb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/view_spec.app.minitest.rb'), 'spec/views/books/index_spec.rb')
          end
        end

        it 'skips the view' do
          with_temp_dir do |original_wd|
            setup_app_app

            command = Lotus::Commands::Generate::Action.new({skip_view: true}, 'testapp', 'books#index')
            capture_io { command.start }

            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/routes.get.rb'), 'config/routes.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action_spec.app.minitest.rb'), 'spec/controllers/books/index_spec.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action_without_view.app.rb'), 'app/controllers/books/index.rb')

            refute File.exist?('apps/web/views/books/index.rb')
            refute File.exist?('apps/web/templates/books/index.html.erb')
            refute File.exist?('spec/web/views/books/index_spec.rb')
          end
        end
      end

      describe 'with rspec' do
        it 'generates the files' do
          with_temp_dir do |original_wd|
            setup_app_app

            command = Lotus::Commands::Generate::Action.new({test: 'rspec'}, 'testapp', 'books#index')
            capture_io { command.start }

            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/routes.get.rb'), 'config/routes.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action_spec.app.rspec.rb'), 'spec/controllers/books/index_spec.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action.app.rb'), 'app/controllers/books/index.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/view.app.rb'), 'app/views/books/index.rb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/template.html.erb'), 'app/templates/books/index.html.erb')
            assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/view_spec.app.rspec.rb'), 'spec/views/books/index_spec.rb')
          end
        end
      end
    end
  end
  describe 'with quoted arguments' do
    # See https://github.com/lotus/lotus/issues/282
    it 'accepts single quoted arguments' do
      with_temp_dir do |original_wd|
        setup_container_app
        command = Lotus::Commands::Generate::Action.new({}, 'web', "'books#index'")
        capture_io { command.start }

        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/routes.get.rb'), 'apps/web/config/routes.rb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action_spec.container.minitest.rb'), 'spec/web/controllers/books/index_spec.rb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action.container.rb'), 'apps/web/controllers/books/index.rb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/view.container.rb'), 'apps/web/views/books/index.rb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/template.html.erb'), 'apps/web/templates/books/index.html.erb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/view_spec.container.minitest.rb'), 'spec/web/views/books/index_spec.rb')
      end
    end

    it 'accepts double quoted arguments' do
      with_temp_dir do |original_wd|
        setup_container_app
        command = Lotus::Commands::Generate::Action.new({}, 'web', '"books#index"')
        capture_io { command.start }

        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/routes.get.rb'), 'apps/web/config/routes.rb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action_spec.container.minitest.rb'), 'spec/web/controllers/books/index_spec.rb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action.container.rb'), 'apps/web/controllers/books/index.rb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/view.container.rb'), 'apps/web/views/books/index.rb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/template.html.erb'), 'apps/web/templates/books/index.html.erb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/view_spec.container.minitest.rb'), 'spec/web/views/books/index_spec.rb')
      end
    end

    it 'accepts escaped arguments' do
      with_temp_dir do |original_wd|
        setup_container_app
        command = Lotus::Commands::Generate::Action.new({}, 'web', 'books\#index')
        capture_io { command.start }

        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/routes.get.rb'), 'apps/web/config/routes.rb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action_spec.container.minitest.rb'), 'spec/web/controllers/books/index_spec.rb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/action.container.rb'), 'apps/web/controllers/books/index.rb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/view.container.rb'), 'apps/web/views/books/index.rb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/template.html.erb'), 'apps/web/templates/books/index.html.erb')
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/action/view_spec.container.minitest.rb'), 'spec/web/views/books/index_spec.rb')
      end
    end
  end

  def setup_container_app
    Lotus::Lotusrc.new(Pathname.new('.'), architecture: 'container')

    FileUtils.mkdir_p('apps/web') # simulate existing app
    FileUtils.mkdir_p('apps/web/config') # simulate existing routes file to see if route is prepended
    File.open('apps/web/config/routes.rb', 'w') { |file| file << "get '/cars', to: 'cars#index'"}
  end

  def setup_app_app
    Lotus::Lotusrc.new(Pathname.new('.'), architecture: 'app')
    FileUtils.mkdir_p('app') # simulate existing app
    FileUtils.mkdir_p('config') # simulate existing routes file to see if route is prepended
    File.open('config/routes.rb', 'w') { |file| file << "get '/cars', to: 'cars#index'"}
  end
end
