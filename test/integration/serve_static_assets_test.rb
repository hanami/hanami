require 'test_helper'
require 'support/isolated'

describe 'Serve static assets (Container)' do
  include Minitest::Isolated
  let(:root) { FIXTURES_ROOT.join('static_assets') }

  it "serves static files that are already in public/" do
    asset    = root.join('public', 'favicon.ico')
    response = get('/favicon.ico')

    response.status.must_equal 200
    response.headers['Content-Length'].to_i.must_equal asset.size
  end

  it "serves static files" do
    response = get '/assets/application.css'
    asset    = root.join('public', 'assets', 'application.css')

    assert asset.exist?, "Expected #{ asset } to be precompiled in #{ root.join('public') }"

    response.status.must_equal 200
    response.headers['Content-Length'].to_i.must_equal asset.size
    response.body.must_equal                           asset.read
  end

  it "serves static files without leading slash" do
    response = get 'assets/application.css'
    asset    = root.join('public', 'assets', 'application.css')

    assert asset.exist?, "Expected #{ asset } to be precompiled in #{ root.join('public') }"

    response.status.must_equal 200
    response.headers['Content-Length'].to_i.must_equal asset.size
    response.body.must_equal                           asset.read
  end

  it "serves static files from nested app" do
    response = get '/assets/admin/application.css'
    asset    = root.join('public', 'assets', 'admin', 'application.css')

    assert asset.exist?, "Expected #{ asset } to be precompiled in #{ root.join('public') }"

    response.status.must_equal 200
    response.headers['Content-Length'].to_i.must_equal asset.size
    response.body.must_equal                           asset.read
  end

  it "precompiles asset and serves it" do
    response = get '/assets/home.css'
    asset    = root.join('public', 'assets', 'home.css')

    assert asset.exist?, "Expected #{ asset } to be precompiled in #{ root.join('public') }"

    response.status.must_equal 200
    response.headers['Content-Length'].to_i.must_equal asset.size
    response.body.must_equal                           asset.read
  end

  it "responds with 'Not Found' when asset cannot be found" do
    response = get '/assets/not-found.css'
    asset    = root.join('public', 'assets', 'not-found.css')

    assert !asset.exist?, "Expected #{ asset } to not exist in #{ root.join('public') }"
    response.status.must_equal 404
  end

  it "replaces fresh version of assets by copying it" do
    begin
      fixture  = root.join('apps', 'web', 'assets', 'javascripts', 'dashboard.js')
      asset    = root.join('public', 'assets', 'dashboard.js')

      asset.delete if asset.exist?
      @assets_directory.mkpath

      File.open(asset, File::WRONLY|File::CREAT) do |f|
        f.write <<-JS
  console.log('stale');
JS
      end

      response = get '/assets/dashboard.js'
      response.body.must_include 'stale'

      sleep 1

      File.open(fixture, File::WRONLY|File::CREAT) do |f|
        f.write <<-JS
  console.log('fresh');
JS
      end

      sleep 1

      response = get '/assets/dashboard.js'
      response.body.must_include 'fresh'
    ensure
      fixture.delete if fixture.exist?
    end
  end

  it "sends HTTP cache headers"
end

describe 'Serve static assets (Application)' do
  include Minitest::Isolated
  let(:root) { FIXTURES_ROOT.join('static_assets_app') }

  it "serves static files that are already in public/" do
    asset    = root.join('public', 'favicon.ico')
    response = get('/favicon.ico')

    response.status.must_equal 200
    response.headers['Content-Length'].to_i.must_equal asset.size
  end

  it "serves static files" do
    response = get '/assets/application.css'
    asset    = root.join('public', 'assets', 'application.css')

    assert asset.exist?, "Expected #{ asset } to be precompiled in #{ root.join('public') }"

    response.status.must_equal 200
    response.headers['Content-Length'].to_i.must_equal asset.size
    response.body.must_equal                           asset.read
  end

  it "serves static files without leading slash" do
    response = get 'assets/application.css'
    asset    = root.join('public', 'assets', 'application.css')

    assert asset.exist?, "Expected #{ asset } to be precompiled in #{ root.join('public') }"

    response.status.must_equal 200
    response.headers['Content-Length'].to_i.must_equal asset.size
    response.body.must_equal                           asset.read
  end

  it "precompiles asset and serves it" do
    response = get '/assets/home.css'
    asset    = root.join('public', 'assets', 'home.css')

    assert asset.exist?, "Expected #{ asset } to be precompiled in #{ root.join('public') }"

    response.status.must_equal 200
    response.headers['Content-Length'].to_i.must_equal asset.size
    response.body.must_equal                           asset.read
  end

  it "responds with 'Not Found' when asset cannot be found" do
    response = get '/assets/not-found.css'
    asset    = root.join('public', 'assets', 'not-found.css')

    assert !asset.exist?, "Expected #{ asset } to not exist in #{ root.join('public') }"
    response.status.must_equal 404
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

      response = get '/assets/dashboard.js'
      response.body.must_include 'stale'

      sleep 1

      File.open(fixture, File::WRONLY|File::CREAT) do |f|
        f.write <<-JS
  console.log('fresh');
JS
      end

      sleep 1

      response = get '/assets/dashboard.js'
      response.body.must_include 'fresh'
    ensure
      fixture.delete if fixture.exist?
    end
  end
end
