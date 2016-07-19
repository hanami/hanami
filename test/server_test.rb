require 'test_helper'
require 'hanami/server'

describe 'Server' do
  it 'adds Hanami::Static to development middleware statck' do
    middlewares = Hanami::Server.new({}).middleware['development'].map(&:name)
    middlewares.must_include('Hanami::Assets::Static')
  end
end
