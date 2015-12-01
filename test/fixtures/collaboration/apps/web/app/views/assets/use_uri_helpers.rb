module Collaboration::Views::Assets
  class UseUriHelpers
    include Collaboration::View

    def asset_path_from_view
      asset_path('application.jpg')
    end

    def asset_url_from_view
      asset_url('application.jpg')
    end
  end
end
