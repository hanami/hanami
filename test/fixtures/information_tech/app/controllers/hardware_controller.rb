module HardwareController
  class Index
    include Hanami::Action

    def call(params)
    end
  end

  class Error
    include Hanami::Action

    def call(params)
      raise 'boom'
    end
  end

  class Legacy
    include Hanami::Action

    def call(params)
      redirect_to 'http://localhost/hardware'
    end
  end

  class Protected
    include Hanami::Action

    def call(params)
      halt 401
    end
  end
end
