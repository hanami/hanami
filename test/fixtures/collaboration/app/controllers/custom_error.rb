module Collaboration::Controllers::CustomError
  include Collaboration::Controller

  action 'Index' do
    def call(params)
      halt 418
    end
  end
end
