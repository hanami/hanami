require 'test_helper'
require 'lotus/root'

describe 'Lotus' do
  describe '.root' do
    let(:pathname) { Lotus.root }
    it 'returns root path' do
      pwd = Pathname.getwd
      pathname.must_equal pwd
    end
  end
end