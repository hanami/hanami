module Collaboration::Controllers::Authors
  class Create
    include Collaboration::Action

    def call(params)
      verify_csrf_token
      # pretend it was going to persist
    end
  end

  class Update
    include Collaboration::Action

    def call(params)
      verify_csrf_token
      # pretend it was going to persist
    end
  end

  class Destroy
    include Collaboration::Action

    def call(params)
      verify_csrf_token
      # pretend it was going to persist
    end
  end
end
