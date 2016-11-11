require 'test_helper'

describe Hanami::VERSION do
  it 'returns current version' do
    Hanami::VERSION.must_equal '0.9.0'
  end
end
