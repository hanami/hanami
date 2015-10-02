require 'spec_helper'

describe Mailers::ForgotPassword do
  it 'delivers email' do
    mail = Mailers::ForgotPassword.deliver
  end
end
