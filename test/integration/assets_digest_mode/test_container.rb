require 'integration_helper'

describe 'Render assets path with digest mode (Container)' do
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
    @app = Lotus::Container.new
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

  let(:root)             { FIXTURES_ROOT.join('static_assets') }
  let(:public_directory) { root.join('public') }
  let(:assets_directory) { public_directory.join('assets') }

  it "renders with digest mode" do
    get '/'

    body = response.body
    body.must_include %(<link href="/assets/application-1e7f8e4a4ea8bd7ca5e7e4f37ff9c898.css" type="text/css" rel="stylesheet">)
    body.must_include %(<link href="/assets/home-fc1454db4345366035149b045c3dba00.css" type="text/css" rel="stylesheet">)
  end
end
