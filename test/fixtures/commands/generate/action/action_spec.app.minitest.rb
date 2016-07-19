require 'spec_helper'
require_relative '../../../app/controllers/books/index'

describe TestApp::Controllers::Books::Index do
  let(:action) { TestApp::Controllers::Books::Index.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
