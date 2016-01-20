require 'integration_helper'

describe 'CDN (Application)' do
  include Minitest::IsolationTest

  before do
    @current_dir = Dir.pwd
    Dir.chdir root

    @hanami_env       = ENV['HANAMI_ENV']
    ENV['HANAMI_ENV'] = 'production'

    assert system("HANAMI_ENV=production bundle exec hanami assets precompile")

    require root.join('config', 'environment')
    @app = CdnApp::Application.new
  end

  after do
    ENV['HANAMI_ENV'] = @hanami_env

    Dir.chdir @current_dir
    @current_dir = nil
  end

  let(:root) { FIXTURES_ROOT.join('cdn', 'cdn_app') }

  it "uses CDN url for asset" do
    body = get("/").body

    body.must_include %(<link href="https://cdn.example.org/assets/favicon-4b49a383ea9cf9a46820b3a2374de6fe.ico" rel="shortcut icon" type="image/x-icon">)
    body.must_include %(<link href="https://cdn.example.org/assets/charge-b45434daf18d5b0deb8aeab4220f5b86.css" type="text/css" rel="stylesheet">)
  end
end
