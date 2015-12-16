require 'integration_helper'

describe 'Precompile static assets (Container)' do
  before do
    assets_directory.rmtree if assets_directory.exist?

    manifest = public_directory.join('assets.json')
    manifest.delete if manifest.exist?

    @current_dir = Dir.pwd
    Dir.chdir root

    @lotus_env = ENV['LOTUS_ENV']
    ENV['LOTUS_ENV'] = 'production'
  end

  after do
    ENV['LOTUS_ENV'] = @lotus_env
    Dir.chdir @current_dir
    @current_dir = nil
  end

  let(:root)             { FIXTURES_ROOT.join('static_assets') }
  let(:public_directory) { root.join('public') }
  let(:assets_directory) { public_directory.join('assets') }

  it 'precompiles assets' do
    `bundle exec lotus assets precompile`

    public_directory.join('assets.json').must_be :exist?

    assets_directory.join('favicon.ico').must_be :exist?
    assets_directory.join('favicon-04115b81b60f4303104a28aba667ab16.ico').must_be :exist?

    assets_directory.join('application.css').must_be :exist?
    assets_directory.join('application-1e7f8e4a4ea8bd7ca5e7e4f37ff9c898.css').must_be :exist?

    assets_directory.join('home.css').must_be :exist?
    assets_directory.join('home-fc1454db4345366035149b045c3dba00.css').must_be :exist?
  end
end
