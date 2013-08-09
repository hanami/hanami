module Posts
  module Views
    class Index
      include Lotus::View

      def page_title
        "#{ layout.page_title }Posts"
      end
    end
  end
end
