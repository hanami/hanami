class ApplicationLayout
  include Lotus::View::Layout
  root __dir__

  def page_title
    "Blog: "
  end
end
