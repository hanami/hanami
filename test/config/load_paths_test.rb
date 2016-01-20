require 'test_helper'

describe Hanami::Config::LoadPaths do
  describe '#load!' do
    it 'recursively loads all the ruby files in the paths' do
      paths = Hanami::Config::LoadPaths.new
      paths << '../fixtures/mail_app/app'
      paths.load!(Pathname(__dir__))

      assert defined?(MailApp::DashboardController), 'expected MailApp::DashboardController'
    end
  end
end
