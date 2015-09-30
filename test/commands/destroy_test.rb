require "test_helper"
require "lotus/cli"
require "lotus/commands/destroy"

describe Lotus::Commands::Destroy do

  let(:app_name) { 'web' }

  def prepare_temporary_dir
    @tmp = Pathname.new(@pwd = Dir.pwd).join('tmp/destroy_test')
    @tmp.rmtree if @tmp.exist?
    @tmp.mkpath

    app_root = @tmp.join('apps', app_name)
    app_root.join('controllers', 'dashboard').mkpath
    app_root.join('templates', 'dashboard').mkpath
    app_root.join('views', 'dashboard').mkpath

    spec_root = @tmp.join('spec')
    spec_root.join(app_name, 'controllers', 'dashboard').mkpath
    spec_root.join(app_name, 'views', 'dashboard').mkpath

    @action_path = Pathname.new("#{app_root}/controllers/dashboard/index.rb")
    @template_path = Pathname.new("#{app_root}/templates/dashboard/index.html.erb")
    @view_path = Pathname.new("#{app_root}/views/dashboard/index.rb")
    @action_spec_path = Pathname.new("#{spec_root}/#{app_name}/controllers/dashboard/index_spec.rb")
    @view_spec_path = Pathname.new("#{spec_root}/#{app_name}/views/dashboard/index_spec.rb")

    FileUtils.touch(@action_path)
    FileUtils.touch(@template_path)
    FileUtils.touch(@view_path)
    FileUtils.touch(@action_spec_path)
    FileUtils.touch(@view_spec_path)
  end

  def chdir_to_temporary
    Dir.chdir(@tmp)
    @root = @tmp
  end

  def chdir_back_to_root
    Dir.chdir(@pwd)
  end

  def default_options
    Hash[path: 'apps']
  end

  before do
    prepare_temporary_dir
    chdir_to_temporary
  end

  after do
    chdir_back_to_root
  end

  describe 'action' do

    let(:command) { Lotus::Commands::Destroy.new(type, app_name, target_name, env, cli) }
    let(:type) { 'action' }
    let(:target_name) { 'dashboard#index' }
    let(:env) { Lotus::Environment.new(default_options) }
    let(:cli) { Lotus::Cli.new }

    before do
      command.start
    end

    it 'deletes the action file' do
      FileTest.exist?(@action_path).must_equal false
    end

    it 'deletes the template file' do
      FileTest.exist?(@template_path).must_equal false
    end

    it 'deletes the view file' do
      FileTest.exist?(@view_path).must_equal false
    end

    it 'deletes the action spec file' do
      FileTest.exist?(@action_spec_path).must_equal false
    end

    it 'deletes the view spec file' do
      FileTest.exist?(@view_spec_path).must_equal false
    end

  end

end
