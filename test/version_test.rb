require 'test_helper'

describe Lotus do
  describe 'version' do
    it 'declares framework version' do
      Lotus::VERSION.must_equal '0.0.1'
    end
  end
end
