require 'test_helper'

describe Lotus::Config::LoadPaths do
  describe '#load!' do
    it 'recursively loads all the ruby files in the paths' do
      paths = Lotus::Config::LoadPaths.new(__dir__ + '/../fixtures/mail_app/app')
      paths.load!

      assert defined?(MailApp::DashboardController), 'expected MailApp::DashboardController'
    end
  end
end
