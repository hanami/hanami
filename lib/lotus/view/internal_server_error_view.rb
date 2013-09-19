module Lotus
  module View
    class InternalServerErrorView
      include Lotus::View

      layout nil
      template '**/500'
    end
  end
end
