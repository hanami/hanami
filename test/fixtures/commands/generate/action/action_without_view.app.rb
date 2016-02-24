module TestApp::Controllers::Books
  class Index
    include TestApp::Action

    def call(params)
      self.body = 'OK'
    end
  end
end
