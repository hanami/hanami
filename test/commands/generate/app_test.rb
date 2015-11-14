require 'test_helper'
require 'lotus/commands/generate/app'
require 'fileutils'

describe Lotus::Commands::Generate::App do
  describe 'with invalid arguments' do
    it 'requires application name' do
      -> { Lotus::Commands::Generate::App.new({}, nil) }.must_raise ArgumentError
      -> { Lotus::Commands::Generate::App.new({}, '') }.must_raise ArgumentError
      -> { Lotus::Commands::Generate::App.new({}, '   ') }.must_raise ArgumentError
    end
  end

  describe 'with valid arguments' do
    it 'generates configuration and template files' do
      with_temp_dir do |original_wd|
        setup_container_app(original_wd)
        command = Lotus::Commands::Generate::App.new({}, 'admin')
        capture_io { command.start }

        # check 'require' and 'mount'
        assert_generated_file(original_wd.join('test', 'fixtures', 'commands', 'generate', 'app', 'environment_with_app_added.rb'), 'config/environment.rb')

        # check .env files
        ['test', 'development'].each do |env|
          content = File.read(".env.#{env}")
          assert (content =~ /ADMIN_SESSIONS_SECRET=\"[a-f, 0-9]{64}\"/), "Expected '#{content}' to contain a session secret property."
        end

        assert_generated_file(original_wd.join('test', 'fixtures', 'commands', 'generate', 'app', 'application.rb'), 'apps/admin/application.rb')
        assert_generated_file(original_wd.join('test', 'fixtures', 'commands', 'generate', 'app', 'layout.rb'), 'apps/admin/views/application_layout.rb')
        assert_generated_file(original_wd.join('test', 'fixtures', 'commands', 'generate', 'app', 'layout.html.erb'), 'apps/admin/templates/application.html.erb')
        assert_generated_file(original_wd.join('test', 'fixtures', 'commands', 'generate', 'app', 'routes.rb'), 'apps/admin/config/routes.rb')
      end
    end

    it 'create files' do
      with_temp_dir do |original_wd|
        setup_container_app(original_wd)
        command = Lotus::Commands::Generate::App.new({}, 'api')
        capture_io { command.start }

        assert_file_exists('apps/api/application.rb')
        assert_file_exists('apps/api/views/application_layout.rb')
        assert_file_exists('apps/api/templates/application.html.erb')
        assert_file_exists('apps/api/config/routes.rb')
        assert_file_exists('apps/api/controllers/.gitkeep')
        assert_file_exists('apps/api/public/javascripts/.gitkeep')
        assert_file_exists('apps/api/public/stylesheets/.gitkeep')
        assert_file_exists('spec/api/features/.gitkeep')
        assert_file_exists('spec/api/controllers/.gitkeep')
        assert_file_exists('spec/api/views/.gitkeep')
      end
    end

    it 'allows to specify the url' do
      with_temp_dir do |original_wd|
        setup_container_app(original_wd)
        command = Lotus::Commands::Generate::App.new({application_base_url: '/backend'}, 'admin')
        capture_io { command.start }

        assert_generated_file(original_wd.join('test', 'fixtures', 'commands', 'generate', 'app', 'environment_with_app_added_url.rb'), 'config/environment.rb')
      end
    end
  end

  it 'can not run for app architecture' do
    with_temp_dir do |original_wd|
      File.open('.lotusrc', 'w') { |file| file << "architecture=app"}
      -> { Lotus::Commands::Generate::App.new({}, 'admin') }.must_raise ArgumentError
    end
  end

  describe '#destroy' do
    it 'destroys destroy an application, along with templates and specs' do
      with_temp_dir do |original_wd|
        setup_container_app(original_wd)
        capture_io {
          Lotus::Commands::Generate::App.new({}, 'api').start
          Lotus::Commands::Generate::App.new({}, 'api').destroy.start
        }
        refute_file_exists('apps/api/application.rb')
        refute_file_exists('apps/api/views/application_layout.rb')
        refute_file_exists('apps/api/templates/application.html.erb')
        refute_file_exists('apps/api/config/routes.rb')
        refute_file_exists('apps/api/controllers/.gitkeep')
        refute_file_exists('apps/api/public/javascripts/.gitkeep')
        refute_file_exists('apps/api/public/stylesheets/.gitkeep')
        refute_file_exists('spec/api/features/.gitkeep')
        refute_file_exists('spec/api/controllers/.gitkeep')
        refute_file_exists('spec/api/views/.gitkeep')
      end
    end
  end

  def setup_container_app(original_wd)
    source = original_wd.join('test', 'fixtures', 'commands', 'generate', 'app', 'environment.rb')
    target = 'config/environment.rb'
    FileUtils.mkdir_p(File.dirname(target))
    FileUtils.cp(source, target)

    FileUtils.touch('.env.test')
    FileUtils.touch('.env.development')
  end
end
