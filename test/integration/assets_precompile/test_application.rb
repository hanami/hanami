require 'integration_helper'

describe 'Precompile static assets (Application)' do
  before do
    assets_directory.rmtree if assets_directory.exist?

    manifest = public_directory.join('assets.json')
    manifest.delete if manifest.exist?

    @current_dir = Dir.pwd
    Dir.chdir root

    @hanami_env = ENV['HANAMI_ENV']
    ENV['HANAMI_ENV'] = 'production'
  end

  after do
    ENV['HANAMI_ENV'] = @hanami_env
    Dir.chdir @current_dir
    @current_dir = nil
  end

  let(:root)             { FIXTURES_ROOT.join('static_assets_app') }
  let(:public_directory) { root.join('public') }
  let(:assets_directory) { public_directory.join('assets') }

  it 'precompiles assets' do
    `bundle exec hanami assets precompile`

    public_directory.join('assets.json').must_be :exist?

    assets_directory.join('favicon.ico').must_be :exist?
    assets_directory.join('favicon-04115b81b60f4303104a28aba667ab16.ico').must_be :exist?

    assets_directory.join('application.css').must_be :exist?
    assets_directory.join('application-5ebdabab46f08c2cc8d56425bb34bc38.css').must_be :exist?

    assets_directory.join('home.css').must_be :exist?
    assets_directory.join('home-c229183232e6cfbf965a21ec0b06ee06.css').must_be :exist?
  end
end
