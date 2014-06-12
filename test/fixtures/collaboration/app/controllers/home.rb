module Collaboration::Controllers::Home
  include Collaboration::Controller

  action 'Index' do
    def call(params)
    end
  end

  action 'Error' do
    def call(params)
      raise StandardError
    end
  end
end
