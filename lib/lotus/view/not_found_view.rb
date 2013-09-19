module Lotus
  module View
    class NotFoundView
      include Lotus::View

      layout nil
      template '**/404'
    end
  end
end
