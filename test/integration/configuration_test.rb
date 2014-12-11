require 'test_helper'
require 'rack/test'
require 'fixtures/configurable/application'

describe 'Configurable application' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('configurable')
    @app = Configurable::Application.new
  end

  after do
    Dir.chdir @current_dir
    @current_dir = nil
  end

  def app
    @app
  end

  def response
    last_response
  end

  def request
    last_request
  end

  describe "when it doesn't handle exceptions" do
    it 'let it to be raised' do
      -> { get '/error' }.must_raise(ArgumentError)
    end
  end

  describe 'configure a framework' do
    it 'yields "configure" blocks when the application is initialized' do
      get '/twist'

      response.body.must_equal 'authenticated'
    end
  end

  describe "model configuration" do
    it 'forwards settings' do
      adapter = Configurable::Model.configuration.instance_variable_get(:@adapter)
      adapter.must_be_kind_of(Lotus::Model::Adapters::MemoryAdapter)
    end
  end

  describe "controller configuration" do
    it 'forwards settings' do
      Configurable::Controller.configuration.default_format.must_equal  :xml
      Configurable::Controller.configuration.default_charset.must_equal 'koi8-r'
    end
  end

  describe "view configuration" do
    it 'forwards settings' do
      Configurable::View.configuration.root.must_equal Pathname.new(@current_dir)
    end
  end
end
