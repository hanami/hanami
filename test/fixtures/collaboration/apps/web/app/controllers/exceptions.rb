module Collaboration::Controllers::Exceptions
  class ViewException
    include Collaboration::Action

    def call(params)
    end
  end

  class TemplateException
    include Collaboration::Action

    def call(params)
    end
  end
end
