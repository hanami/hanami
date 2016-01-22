require 'test_helper'
require 'hanami/commands/routes'
require 'hanami/container'

describe Hanami::Commands::Routes do
  let(:opts)   { Hash.new }
  let(:env)    { Hanami::Environment.new(opts) }
  let(:routes) { Hanami::Commands::Routes.new(env) }

  describe 'container architecture' do
    def architecture_options
      Hash[architecture: architecture, environment: 'test/fixtures/microservices/config/environment']
    end

    let(:opts)         { architecture_options }
    let(:architecture) { 'container' }

    before do
      Hanami::Container.configure do
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

        actual = Hanami::Container.new.routes.inspector.to_s
        expectations.each do |expectation|
          actual.must_include(expectation)
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
      Hanami::Application.applications.clear

      class MySingleApplication < Hanami::Application
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

        actual = Hanami::Application.applications.first.new.routes.inspector.to_s
        expectations.each do |expectation|
          actual.must_include(expectation)
        end
      end
    end
  end
end
