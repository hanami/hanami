require 'integration_helper'

describe 'Serve static assets (Container - production)' do
  include Minitest::IsolationTest

  before do
    @assets_directory = root.join('public', 'assets')
    @assets_directory.rmtree if @assets_directory.exist?

    @current_dir = Dir.pwd
    Dir.chdir root
    @hanami_env                = ENV['HANAMI_ENV']
    ENV['HANAMI_ENV']          = 'production'
    ENV['SERVE_STATIC_ASSETS'] = 'true'

    require root.join('config', 'environment')
    @app = Hanami::Container.new

    Hanami::Assets.configuration.public_directory Hanami.public_directory
    Hanami::Assets.deploy
  end

  after do
    Dir.chdir @current_dir
    ENV['SERVE_STATIC_ASSETS'] = 'false'
    ENV['HANAMI_ENV']          = @hanami_env
    @current_dir = nil
  end

  let(:root) { FIXTURES_ROOT.join('static_assets') }

  describe 'production mode' do
    it "responds from application route" do
      get '/'

      response.status.must_equal 200
      response.body.must_match   'Hello'
    end

    it "serves static files" do
      get '/assets/application.css'
      asset = root.join('public', 'assets', 'application.css')

      response.status.must_equal 200
      response.headers['Content-Length'].to_i.must_equal asset.size
      response.headers['Cache-Control'].must_equal       "public, max-age=31536000"
      response.body.must_equal                           asset.read
    end

    it "serves static files that is in public directory" do
      get '/robots.txt'
      asset = root.join('public', 'robots.txt')

      response.status.must_equal 200
      response.headers['Content-Length'].to_i.must_equal asset.size
      response.headers['Cache-Control'].must_equal       "public, max-age=31536000"
      response.body.must_equal                           asset.read
    end
  end
end

