module Testapp::Controllers::Books
  class Index
    include Testapp::Action

    def call(params)
      self.body = 'OK'
    end
  end
end
