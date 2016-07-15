require 'integration_helper'

describe 'Serve static assets (Application - development)' do
  include Minitest::IsolationTest

  before do
    @assets_directory = root.join('public', 'assets')
    @assets_directory.rmtree if @assets_directory.exist?

    @current_dir = Dir.pwd
    Dir.chdir root
    ENV['SERVE_STATIC_ASSETS'] = 'true'

    require root.join('config', 'environment')
    @app = StaticAssetsApp::Application.new
  end

  after do
    Dir.chdir @current_dir
    ENV['SERVE_STATIC_ASSETS'] = 'false'
    @current_dir = nil
  end

  let(:root) { FIXTURES_ROOT.join('static_assets_app') }

  it "responds from application route" do
    get '/'

    response.status.must_equal 200
    response.body.must_match   'Hello'

    assert !response.headers.key?('Cache-Control'),
      "Expected response to NOT send Cache-Control header"
  end

  it "serves static files" do
    get '/assets/application.css'
    asset = root.join('public', 'assets', 'application.css')

    response.status.must_equal 200
    response.headers['Content-Length'].to_i.must_equal asset.size
    response.body.must_equal                           asset.read

    assert !response.headers.key?('Cache-Control'),
      "Expected response to NOT send Cache-Control header"

    assert asset.exist?, "Expected #{ asset } to be precompiled in #{ root.join('public') }"
  end

  it "serves static files without leading slash" do
    get 'assets/application.css'
    asset = root.join('public', 'assets', 'application.css')

    assert asset.exist?, "Expected #{ asset } to be precompiled in #{ root.join('public') }"

    response.status.must_equal 200
    response.headers['Content-Length'].to_i.must_equal asset.size
    response.body.must_equal                           asset.read
  end

  it "serves static files that is in public directory" do
    get '/robots.txt'
    asset = root.join('public', 'robots.txt')

    response.status.must_equal 200
    response.headers['Content-Length'].to_i.must_equal asset.size
    response.body.must_equal                           asset.read

    assert !response.headers.key?('Cache-Control'),
      "Expected response to NOT send Cache-Control header"

    assert asset.exist?, "Expected #{ asset } to be served from #{ root.join('public') }"
  end

  it "compiles asset and serves it" do
    get '/assets/home.css'
    asset = root.join('public', 'assets', 'home.css')

    assert asset.exist?, "Expected #{ asset } to be compiled and served from #{ root.join('public') }"

    response.status.must_equal 200
    response.headers['Content-Length'].to_i.must_equal asset.size
    response.body.must_equal                           asset.read
  end

  it "responds with 'Not Found' when asset cannot be found" do
    get '/assets/not-found.css'
    asset = root.join('public', 'assets', 'not-found.css')

    assert !asset.exist?, "Expected #{ asset } to not exist in #{ root.join('public') }"
    response.status.must_equal 404
  end

  it "does not block application path" do
    asset = root.join('public', 'assets', 'dashboard.js')
    @assets_directory.mkpath

    File.open(asset, File::WRONLY|File::CREAT) do |f|
      f.write <<-JS
  console.log('stale');
      JS
    end

    get 'dashboard'
    response.status.must_equal 200
    response.body.must_include 'dashboard'
    asset.delete if asset.exist?
  end

  it "replaces fresh version of assets by copying it" do
    begin
      fixture  = root.join('app', 'assets', 'javascripts', 'dashboard.js')
      asset    = root.join('public', 'assets', 'dashboard.js')

      asset.delete if asset.exist?
      @assets_directory.mkpath

      File.open(asset, File::WRONLY|File::CREAT) do |f|
        f.write <<-JS
  console.log('stale');
JS
      end

      get 'assets/dashboard.js'
      response.body.must_include 'stale'

      sleep 1

      File.open(fixture, File::WRONLY|File::CREAT) do |f|
        f.write <<-JS
  console.log('fresh');
JS
      end

      sleep 1

      get '/assets/dashboard.js'
      response.body.must_include 'fresh'
    ensure
      fixture.delete if fixture.exist?
    end
  end

  it "replaces fresh version of asset if a dependency has changed" do
    begin
      dependency = root.join('app', 'assets', 'stylesheets', '_background.sass')
      fixture    = root.join('app', 'assets', 'stylesheets', 'dashboard.css.sass')
      asset      = root.join('public', 'assets', 'dashboard.css')

      asset.delete if asset.exist?
      @assets_directory.mkpath

      File.open(dependency, File::WRONLY|File::CREAT) do |f|
        f.write <<-CSS
$background-color: #fff
CSS
      end

      sleep 1

      File.open(fixture, File::WRONLY|File::CREAT) do |f|
        f.write <<-CSS
@import "background"

body
  background-color: $background-color
CSS
      end

      get 'assets/dashboard.css'
      response.body.must_include '#fff'

      sleep 1

      File.open(dependency, File::WRONLY|File::CREAT) do |f|
        f.write <<-CSS
$background-color: #000
CSS
      end

      sleep 1

      get '/assets/dashboard.css'
      response.body.must_include '#000'
    ensure
      dependency.delete if dependency.exist?
      fixture.delete    if fixture.exist?
      asset.delete      if asset.exist?
    end
  end
end
