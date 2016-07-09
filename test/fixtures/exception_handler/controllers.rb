module ExceptionHandler
  module Controllers
    module ExceptionalHome
      class ControllerException
        include Hanami::Action

        def call(_params)
          fail Errors::ControllerError
        end
      end

      class ViewException
        include Hanami::Action

        def call(_params); end
      end

      class NoException
        include Hanami::Action

        def call(_params)
          self.body = 'okay, you passed'
          self.status = 200
        end
      end
    end
  end
end
