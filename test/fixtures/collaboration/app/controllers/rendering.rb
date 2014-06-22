module Collaboration::Controllers::Rendering
  include Collaboration::Controller

  action 'Body' do
    def call(params)
      self.body = 'Set by action'
    end
  end

  action 'Presenter' do
    def call(params)
    end
  end
end
