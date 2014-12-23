module HardwareController
  class Index
    include Lotus::Action

    def call(params)
    end
  end

  class Error
    include Lotus::Action

    def call(params)
      raise 'boom'
    end
  end

  class Legacy
    include Lotus::Action

    def call(params)
      redirect_to 'http://localhost/hardware'
    end
  end

  class Protected
    include Lotus::Action

    def call(params)
      halt 401
    end
  end
end
