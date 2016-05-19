require 'test_helper'
require 'hanami/server'

describe 'Server' do
  it 'adds Shotgun::Static when code reloading is enabled' do
    middlewares = Hanami::Server.new(code_reloading: true).middleware['development'].map(&:name)
    middlewares.must_include('Shotgun::Static')
  end

  it 'does not add Shotgun::Static when code reloading is disabled' do
    middlewares = Hanami::Server.new(code_reloading: false).middleware['development'].map(&:name)
    middlewares.wont_include('Shotgun::Static')
  end
end
