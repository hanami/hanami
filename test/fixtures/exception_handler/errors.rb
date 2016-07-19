module ExceptionHandler
  module Errors
    class Base < ::StandardError; end
    class ControllerError < Base; end
    class ViewError < Base; end
  end
end
