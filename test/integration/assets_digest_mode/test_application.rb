require 'integration_helper'

describe 'Render assets path with digest mode (Application)' do
  include Minitest::IsolationTest

  before do
    assets_directory.rmtree if assets_directory.exist?

    manifest = public_directory.join('assets.json')
    manifest.delete if manifest.exist?

    @current_dir = Dir.pwd
    Dir.chdir root

    @lotus_env = ENV['LOTUS_ENV']
    ENV['LOTUS_ENV'] = 'production'

    `bundle exec lotus assets precompile`
    public_directory.join('assets.json').must_be :exist?

    require root.join('config', 'environment')
    @app = StaticAssetsApp::Application.new
  end

  after do
    ENV['LOTUS_ENV'] = @lotus_env
    Dir.chdir @current_dir
    @current_dir = nil

    Dir["#{ public_directory }/**/*"].each do |f|
      next if ::File.directory?(f) || f.match(/favicon\.ico\z/)
      FileUtils.rm(f)
    end
  end

  let(:root)             { FIXTURES_ROOT.join('static_assets_app') }
  let(:public_directory) { root.join('public') }
  let(:assets_directory) { public_directory.join('assets') }

  it "renders with digest mode" do
    get '/'

    body = response.body
    body.must_include %(<link href="/assets/application-5ebdabab46f08c2cc8d56425bb34bc38.css" type="text/css" rel="stylesheet">)
    body.must_include %(<link href="/assets/home-c229183232e6cfbf965a21ec0b06ee06.css" type="text/css" rel="stylesheet">)
  end
end
