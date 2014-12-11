module HardwareController
  class Index
    include InformationTech::Action

    def call(params)
    end
  end

  class Error
    include InformationTech::Action

    def call(params)
      raise 'boom'
    end
  end

  class Legacy
    include InformationTech::Action

    def call(params)
      redirect_to 'http://localhost/hardware'
    end
  end

  class Protected
    include InformationTech::Action

    def call(params)
      halt 401
    end
  end
end
