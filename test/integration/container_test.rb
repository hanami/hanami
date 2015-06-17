require 'test_helper'

describe Lotus::Container do
  describe 'apps mounted with container' do
    it 'should generate correct paths with route helper' do
      Lotus::Container.configure do
        mount Admin::Application, at: '/admin'
        mount CallCenter::Application, at: '/callcenter'
      end

      Lotus::Container.new

      CallCenter::Routes.path(:home).must_equal '/callcenter/home'
      Admin::Routes.path(:home).must_equal '/admin/home'
    end
  end
end
