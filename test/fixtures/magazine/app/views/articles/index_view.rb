module Articles
  class IndexView
    include Lotus::View

    def page_title
      "#{ layout.page_title }Articles"
    end
  end
end
