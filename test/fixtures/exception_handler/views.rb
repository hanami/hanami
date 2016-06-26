module ExceptionHandler
  module Views
    module ExceptionalHome
      class ViewException
        include Hanami::View

        def render
          fail Errors::ViewError
        end
      end
    end
  end
end
