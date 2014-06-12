module Collaboration::Controllers::Protected
  include Collaboration::Controller

  action 'Index' do
    def call(params)
      halt 401
    end
  end
end
