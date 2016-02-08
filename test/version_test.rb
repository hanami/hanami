require 'test_helper'

describe Hanami::VERSION do
  it 'returns current version' do
    Hanami::VERSION.must_equal '0.8.0'
  end
end
