RSpec.describe 'rackup', type: :integration do
  it "serves contents from database" do
    with_project do
      setup_model
      console do |input, _, _|
        input.puts("BookRepository.new.create(title: 'Learn Hanami')")
        input.puts("exit")
      end

      generate "action web books#show --url=/books/:id"
      rewrite  "apps/web/controllers/books/show.rb", <<-EOF
module Web::Controllers::Books
  class Show
    include Web::Action
    expose :book

    def call(params)
      @book = BookRepository.new.find(params[:id]) or halt(404)
    end
  end
end
      EOF
      rewrite "apps/web/templates/books/show.html.erb", <<-EOF
<h1><%= book.title %></h1>
      EOF

      rackup do
        visit "/books/1"
        expect(page).to have_content("Learn Hanami")
      end
    end
  end
end
