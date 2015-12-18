require 'spec_helper'
require_relative '../../../../apps/web/controllers/users/show'

describe Web::Controllers::Users::Show do
  let(:action) { Web::Controllers::Users::Show.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
