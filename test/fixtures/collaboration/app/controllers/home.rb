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

  action 'Legacy' do
    def call(params)
      redirect_to Collaboration::Routes.url(:root)
    end
  end
end
