RSpec.describe 'Routing helpers', type: :cli do
  it "uses routing helpers within view" do
    with_project do
      generate "action web books#index --url=/books"
      generate "action web books#show --url=/books/:id"

      # Add `as:` option, so it can be used by the routing helper
      replace "apps/web/config/routes.rb", "/books/:id", "get '/books/:id', to: 'books#show', as: :book"
      rewrite "apps/web/views/books/index.rb", <<-EOF
module Web::Views::Books
  class Index
    include Web::View

    def featured_book_path
      routes.path(:book, id: 23)
    end
  end
end
EOF
      rewrite "apps/web/templates/books/index.html.erb", <<-EOF
<h1>Books</h1>
<h2><a href="<%= featured_book_path %>">Featured Book</a></h2>
EOF

      server do
        visit "/books"

        expect(page.body).to include(%(<a href="/books/23">Featured Book</a>))
      end
    end
  end
end
