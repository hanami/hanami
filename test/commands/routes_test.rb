require 'test_helper'
require 'lotus/commands/routes'
require 'lotus/container'

describe Lotus::Commands::Routes do
  let(:routes) { Lotus::Commands::Routes.new }

  before do
    Lotus::Container.configure do
      mount Backend::App, at: '/backend'
      mount RackApp,      at: '/rackapp'
      mount TinyApp,      at: '/'
    end
  end

  describe '#start' do
    it 'print routes' do
      expectations = [
        %(/backend                       Backend::App),
        %(/rackapp                       RackApp),
        %(GET, HEAD  /                              TinyApp::Controllers::Home::Index)
      ]

      actual = Lotus::Container.new.routes.inspector.to_s
      expectations.each do |expectation|
        actual.must_include(expectation)
      end
    end
  end
end