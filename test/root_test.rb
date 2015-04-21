require 'test_helper'
require 'lotus/root'

describe 'Lotus.root' do
  let(:pathname) {Lotus.root}
  it 'return root path' do
    pwd = Pathname.getwd
    pathname.must_equal pwd
  end
end