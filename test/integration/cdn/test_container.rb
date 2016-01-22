require 'integration_helper'

describe 'CDN (Container)' do
  include Minitest::IsolationTest

  before do
    @assets_directory = root.join('public', 'assets')
    @assets_directory.rmtree if @assets_directory.exist?

    @current_dir = Dir.pwd
    Dir.chdir root

    @hanami_env       = ENV['HANAMI_ENV']
    ENV['HANAMI_ENV'] = 'production'

    assert system("HANAMI_ENV=production bundle exec hanami assets precompile")

    require root.join('config', 'environment')
    @app = Hanami::Container.new
  end

  after do
    ENV['HANAMI_ENV'] = @hanami_env

    Dir.chdir @current_dir
    @current_dir = nil

    @assets_directory.rmtree if @assets_directory.exist?
  end

  let(:root) { FIXTURES_ROOT.join('cdn', 'cdn') }

  it "uses CDN url for asset" do
    body = get("/").body

    body.must_include %(<link href="https://cdn.example.org/assets/favicon-4b49a383ea9cf9a46820b3a2374de6fe.ico" rel="shortcut icon" type="image/x-icon">)
    body.must_include %(<script src="https://cdn.example.org/assets/analytics-9fd60e0c3af3bb376e3c17f65ac751cd.js" type="text/javascript"></script>)
  end
end
