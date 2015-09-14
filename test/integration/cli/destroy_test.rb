require 'test_helper'
require 'fileutils'

describe 'lotus destroy' do
  let(:options)           { '' }
  let(:app_name)          { 'web' }
  let(:architecture)      { 'container' }
  let(:template_engine)   { 'erb' }
  let(:framework_testing) { 'minitest' }

  def setup
    create_temporary_dir
    generate_application
  end

  def teardown
    chdir_to_root
  end

  describe 'when application destroys an action' do
    before do
      generate_action 'dashboard#index'
      generate_action 'playlist#index'
      destroy_action 'dashboard#index'
    end

    it 'removes generated action files' do
      @root.join('apps/web/controllers/dashboard/index.rb').wont_be      :exist?
      @root.join('apps/web/views/dashboard/index.rb').wont_be            :exist?
      @root.join('apps/web/templates/dashboard/index.html.erb').wont_be  :exist?
      @root.join('spec/web/controllers/dashboard/index_spec.rb').wont_be :exist?
      @root.join('spec/web/views/dashboard/index_spec.rb').wont_be       :exist?
    end

    it 'removes generated route' do
      content = @root.join('apps/web/config/routes.rb').read

      content.must_match %(get '/playlist', to: 'playlist#index')
      content.wont_match %(get '/dashboard', to: 'dashboard#index')
    end
  end

  describe 'when application destroys a model' do
    before do
      generate_model 'pizza'
      destroy_model 'pizza'
    end

    it 'removes generated model files' do
      @root.join('lib/delivery/entities/pizza.rb').wont_be                      :exist?
      @root.join('lib/delivery/repositories/pizza_repository.rb').wont_be       :exist?
      @root.join('spec/delivery/entities/pizza_spec.rb').wont_be                :exist?
      @root.join('spec/delivery/repositories/pizza_repository_spec.rb').wont_be :exist?
    end
  end

  describe 'when application destroys a migration' do
    let(:options) { ' --database=sqlite3' }
    let(:migrations_dir) { @root.join('db/migrations') }

    before do
      generate_migration 'create_books'
      destroy_migration 'create_books'
    end

    it 'removes generated migration' do
      Dir.glob("#{ migrations_dir }/[0-9]*_create_books.rb").must_be :empty?
    end
  end

  def generate_action(action)
    `bundle exec lotus generate action #{ app_name } #{ action }`
  end

  def destroy_action(action)
    `bundle exec lotus destroy action #{ app_name } #{ action }`
  end

  def generate_model(model)
    `bundle exec lotus generate model #{ model }`
  end

  def destroy_model(model)
    `bundle exec lotus destroy model #{ model }`
  end

  def generate_migration(migration)
    `bundle exec lotus generate migration #{ migration }`
  end

  def destroy_migration(migration)
    `bundle exec lotus destroy migration #{ migration }`
  end

  def create_temporary_dir
    @tmp = Pathname.new(@pwd = Dir.pwd).join('tmp/integration/cli/generate')
    FileUtils.rm_rf(@tmp)
    @tmp.mkpath

    Dir.chdir(@tmp)
  end

  def generate_application
    `bundle exec lotus new #{ @app_name = 'delivery' } --architecture=#{ architecture }#{ options }`
    Dir.chdir(@root = @tmp.join(@app_name))

    File.open(@root.join('.lotusrc'), 'w') do |f|
      f.write <<-LOTUSRC
architecture=#{ architecture }
test=#{ framework_testing }
template=#{ template_engine }
      LOTUSRC
    end
  end

  def chdir_to_root
    Dir.chdir($pwd)
  end
end
