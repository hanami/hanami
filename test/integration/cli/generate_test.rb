require 'test_helper'

describe 'lotus generate' do
  describe 'action' do
    let(:options) { '' }

    def create_temporary_dir
      @tmp = Pathname.new(@pwd = Dir.pwd).join('tmp/integration/cli/generate')
      @tmp.rmtree if @tmp.exist?
      @tmp.mkpath

      Dir.chdir(@tmp)
    end

    def generate_application
      `bundle exec lotus new #{ @app_name = 'delivery' }#{ options }`
      Dir.chdir(@root = @tmp.join(@app_name))
    end

    def generate_action
      `bundle exec lotus generate action web dashboard#index`
    end

    def chdir_to_root
      Dir.chdir(@pwd)
    end

    before do
      create_temporary_dir
      generate_application
      generate_action
    end

    def after
      chdir_to_root
    end

    it 'generates an action' do
      @root.join('apps/web/controllers/dashboard/index.rb').must_be      :exist?
      @root.join('apps/web/views/dashboard/index.rb').must_be            :exist?
      @root.join('apps/web/templates/dashboard/index.html.erb').must_be  :exist?
      @root.join('spec/web/controllers/dashboard/index_spec.rb').must_be :exist?
      @root.join('spec/web/views/dashboard/index_spec.rb').must_be       :exist?
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
      let(:options) { ' --test=rspec' }

      it 'generates action spec' do
        content = @root.join('spec/web/controllers/dashboard/index_spec.rb').read
        content.must_include %(expect)
      end

      it 'generates view spec' do
        content = @root.join('spec/web/views/dashboard/index_spec.rb').read
        content.must_include %(expect)
      end
    end
  end
end
