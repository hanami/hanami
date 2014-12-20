module Collaboration::Controllers::CustomError
  class Index
    include Collaboration::Action

    def call(params)
      halt 418
    end
  end
end
