require 'test_helper'
require 'rack/test'
require 'fixtures/exception_handler/base'

describe 'Exception handler' do
  include Rack::Test::Methods

  let(:app) { ExceptionHandler::Application.new }

  describe 'rack.exception Rack variable' do
    let(:subject) { last_request.env['rack.exception'] }

    describe 'controller exception' do
      before { get '/controller_exception' }

      it 'sets the variable' do
        subject.must_be_kind_of ExceptionHandler::Errors::ControllerError
      end
    end

    describe 'view exception' do
      it 'sets the variable' do
        -> { get '/view_exception' }.must_raise ExceptionHandler::Errors::ViewError
        subject.must_be_kind_of ExceptionHandler::Errors::ViewError
      end
    end

    describe 'no exception' do
      before { get '/no_exception' }

      it 'does not set the variable' do
        subject.must_be_nil
      end
    end
  end
end
