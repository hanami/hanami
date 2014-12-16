module Collaboration::Controllers::Rendering
  class Body
    include Collaboration::Action

    def call(params)
      self.body = 'Set by action'
    end
  end

  class Presenter
    include Collaboration::Action

    def call(params)
    end
  end
end
