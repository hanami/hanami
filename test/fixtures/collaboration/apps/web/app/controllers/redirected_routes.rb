module Collaboration::Controllers::RedirectedRoutes
  class Index
    include Collaboration::Action

    def call(params)
      redirect_to routes.legacy_path
    end
  end
end
