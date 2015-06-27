require 'test_helper'
require 'lotus/commands/routes'
require 'lotus/container'

describe Lotus::Commands::Routes do
  let(:opts)   { Hash.new }
  let(:env)    { Lotus::Environment.new(opts) }
  let(:routes) { Lotus::Commands::Routes.new(env) }

  describe 'container architecture' do
    def architecture_options
      Hash[architecture: architecture, environment: 'test/fixtures/microservices/config/environment']
    end

    let(:opts)         { architecture_options }
    let(:architecture) { 'container' }

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

        expectations.each do |expectation|
          routes.start.must_include(expectation)
        end
      end
    end
  end

  describe 'application architecture' do
    def architecture_options
      Hash[architecture: architecture, environment: 'test/fixtures/microservices/config/environment']
    end

    let(:opts)         { architecture_options }
    let(:architecture) { 'app' }

    before do
      Lotus::Application.applications.clear

      class MySingleApplication < Lotus::Application
        configure do
          routes do
            get '/',        to: 'home#index'
            get '/welcome', to: 'home#welcome'
          end
        end
      end
    end

    describe '#start' do
      it 'print routes' do
        expectations = [
          %(/                              MySingleApplication::Controllers::Home::Index),
          %(/welcome                       MySingleApplication::Controllers::Home::Welcome)
        ]

        expectations.each do |expectation|
          routes.start.must_include(expectation)
        end
      end
    end
  end
end