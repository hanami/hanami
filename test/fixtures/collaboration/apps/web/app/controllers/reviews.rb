module Collaboration::Controllers::Reviews
  class Create
    include Collaboration::Action

    def call(_params)
      # pretend it was going to persist
      self.status = 201
    end

    private

    def verify_csrf_token?
      false
    end
  end

  class Show
    include Collaboration::Action
    expose :review

    def call(_params)
      self.status = 404
    end

    private

    def verify_csrf_token?
      false
    end
  end

  class Update
    include Collaboration::Action

    def call(_params)
      self.status = 422
    end

    private

    def verify_csrf_token?
      false
    end
  end
end
