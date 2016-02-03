require 'spec_helper'
require_relative '../../../app/controllers/home/dashboard'

describe StaticAssetsApp::Controllers::Home::Dashboard do
  let(:action) { StaticAssetsApp::Controllers::Home::Dashboard.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
