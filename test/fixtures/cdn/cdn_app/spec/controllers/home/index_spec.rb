require 'spec_helper'
require_relative '../../../app/controllers/home/index'

describe CdnApp::Controllers::Home::Index do
  let(:action) { CdnApp::Controllers::Home::Index.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
