module Collaboration::Views::Exceptions
  class ViewException
    include Collaboration::View

    def raise_exception_helper
      raise "View exception"
    end
  end
end
