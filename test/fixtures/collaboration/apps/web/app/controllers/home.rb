module Collaboration::Controllers::Home
  class Index
    include Collaboration::Action

    def call(params)
    end
  end

  class Error
    include Collaboration::Action

    def call(params)
      raise StandardError
    end
  end

  class Legacy
    include Collaboration::Action

    def call(params)
      redirect_to routes.url(:root)
    end
  end
end
