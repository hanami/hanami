require 'test_helper'
require 'hanami/root'

describe 'Hanami' do
  describe '.root' do
    let(:pathname) { Hanami.root }
    it 'returns root path' do
      pwd = Pathname.getwd
      pathname.must_equal pwd
    end
  end
end