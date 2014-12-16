module Collaboration::Controllers::Protected
  class Index
    include Collaboration::Action

    def call(params)
      halt 401
    end
  end
end
