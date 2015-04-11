require 'test_helper'

describe 'lotus generate' do
  describe 'action' do
    let(:options)           { '' }
    let(:app_name)          { 'web' }
    let(:template_engine)   { 'erb' }
    let(:framework_testing) { 'minitest' }
    let(:klass)             { 'test' }

    def create_temporary_dir
      @tmp = Pathname.new(@pwd = Dir.pwd).join('tmp/integration/cli/generate')
      @tmp.rmtree if @tmp.exist?
      @tmp.mkpath

      Dir.chdir(@tmp)
    end

    def generate_application
      `bundle exec lotus new #{ @app_name = 'delivery' }#{ options }`
      Dir.chdir(@root = @tmp.join(@app_name))

      File.open(@root.join('.lotusrc'), 'w') do |f|
        f.write <<-LOTUSRC
architecture=container
test=#{ framework_testing }
template=#{ template_engine }
        LOTUSRC
      end
    end

    def generate_action
      `bundle exec lotus generate action #{ app_name } dashboard#index`
    end

    def generate_action_without_view
      `bundle exec lotus generate action #{ app_name } dashboard#foo --skip-view`
    end

    def generate_model
      `bundle exec lotus generate model #{ klass }`
    end

    def chdir_to_root
      Dir.chdir(@pwd)
    end

    before do
      create_temporary_dir
      generate_application
      generate_action
      generate_action_without_view
      generate_model
    end

    def after
      chdir_to_root
    end

    it 'generates model' do
      @root.join('lib/delivery/entities/test.rb').must_be                      :exist?
      @root.join('lib/delivery/repositories/test_repository.rb').must_be       :exist?
      @root.join('spec/delivery/entities/test_spec.rb').must_be                :exist?
      @root.join('spec/delivery/repositories/test_repository_spec.rb').must_be :exist?
    end

    it 'generates an action' do
      @root.join('apps/web/controllers/dashboard/index.rb').must_be      :exist?
      @root.join('apps/web/views/dashboard/index.rb').must_be            :exist?
      @root.join('apps/web/templates/dashboard/index.html.erb').must_be  :exist?
      @root.join('spec/web/controllers/dashboard/index_spec.rb').must_be :exist?
      @root.join('spec/web/views/dashboard/index_spec.rb').must_be       :exist?
    end

    it 'generates an action without view' do
      @root.join('apps/web/controllers/dashboard/foo.rb').must_be      :exist?
      @root.join('apps/web/views/dashboard/foo.rb').wont_be            :exist?
      @root.join('apps/web/templates/dashboard/foo.html.erb').wont_be  :exist?
      @root.join('spec/web/controllers/dashboard/foo_spec.rb').must_be :exist?
      @root.join('spec/web/views/dashboard/foo_spec.rb').wont_be       :exist?
    end

    describe 'when application is generated with minitest' do
      it 'generates action spec' do
        content = @root.join('spec/web/controllers/dashboard/index_spec.rb').read
        content.must_include %(must_equal)
      end

      it 'generates view spec' do
        content = @root.join('spec/web/views/dashboard/index_spec.rb').read
        content.must_include %(must_equal)
      end
    end

    describe 'when application is generated with rspec' do
      let(:framework_testing) { 'rspec' }

      it 'generates action spec' do
        content = @root.join('spec/web/controllers/dashboard/index_spec.rb').read
        content.must_include %(expect)
      end

      it 'generates view spec' do
        content = @root.join('spec/web/views/dashboard/index_spec.rb').read
        content.must_include %(expect)
      end
    end

    describe 'when application is generated with HAML' do
      let(:template_engine) { 'haml' }

      it 'generates HAML template' do
        @root.join('apps/web/templates/dashboard/index.html.haml').must_be :exist?
      end
    end

    describe 'with unknown application' do
      let(:app_name) { 'unknown' }

      it "doesn't generate the action" do
        @root.join('apps/unknown/controllers/dashboard/index.rb').wont_be      :exist?
        @root.join('apps/unknown/views/dashboard/index.rb').wont_be            :exist?
        @root.join('apps/unknown/templates/dashboard/index.html.erb').wont_be  :exist?
        @root.join('spec/unknown/controllers/dashboard/index_spec.rb').wont_be :exist?
        @root.join('spec/unknown/views/dashboard/index_spec.rb').wont_be       :exist?
      end
    end
  end
end
