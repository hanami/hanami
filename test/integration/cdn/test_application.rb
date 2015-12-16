require 'integration_helper'

describe 'CDN (Application)' do
  include Minitest::IsolationTest

  before do
    @current_dir = Dir.pwd
    Dir.chdir root

    @lotus_env       = ENV['LOTUS_ENV']
    ENV['LOTUS_ENV'] = 'production'

    assert system("LOTUS_ENV=production bundle exec lotus assets precompile")

    require root.join('config', 'environment')
    @app = CdnApp::Application.new
  end

  after do
    ENV['LOTUS_ENV'] = @lotus_env

    Dir.chdir @current_dir
    @current_dir = nil
  end

  let(:root) { FIXTURES_ROOT.join('cdn', 'cdn_app') }

  it "uses CDN url for asset" do
    body = get("/").body

    body.must_include %(<link href="https://cdn.example.org/assets/favicon-4b49a383ea9cf9a46820b3a2374de6fe.ico" rel="shortcut icon" type="image/x-icon">)
    body.must_include %(<link href="https://cdn.example.org/assets/charge-d0ce88a785ae8734d2d802e5a48888d0.css" type="text/css" rel="stylesheet">)
  end
end
