require 'spec_helper'
require_relative '../../../app/controllers/users/show'

describe RakeTasksApp::Controllers::Users::Show do
  let(:action) { RakeTasksApp::Controllers::Users::Show.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
