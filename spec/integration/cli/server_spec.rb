RSpec.describe 'hanami server', type: :cli do
  context "without routes" do
    it "shows welcome page" do
      with_project do
        server do
          visit "/"

          expect(page).to have_title("Hanami | The web, with simplicity")

          expect(page).to have_content("The web, with simplicity.")
          expect(page).to have_content("Hanami is Open Source Software for MVC web development with Ruby.")
          expect(page).to have_content("bundle exec hanami generate action web home#index --url=/")
        end
      end
    end

    it "shows welcome page for generated app" do
      with_project do
        generate "app admin"

        server do
          visit "/admin"

          expect(page).to have_content("bundle exec hanami generate action admin home#index --url=/")
        end
      end
    end
  end

  context "with routes" do
    it "serves action" do
      with_project do
        server do
          generate "action web home#index --url=/"

          visit "/"
          expect(page).to have_title("Web")
        end
      end
    end

    it "serves static asset" do
      with_project do
        server do
          write "apps/web/assets/javascripts/application.js", <<-EOF
console.log('test');
EOF
          visit "/assets/application.js"
          expect(page).to have_content("console.log('test');")
        end
      end
    end

    it "serves contents from database" do
      project = "bookshelf_server_database"

      with_project(project, database: :sqlite) do
        setup_model(project)
        console do |input, _, _|
          input.puts("BookRepository.create(Book.new(title: 'Learn Hanami'))")
          input.puts("exit")
        end

        generate "action web books#show --url=/books/:id"
        rewrite  "apps/web/controllers/books/show.rb", <<-EOF
module Web::Controllers::Books
  class Show
    include Web::Action
    expose :book

    def call(params)
      @book = BookRepository.find(params[:id]) or halt(404)
    end
  end
end
EOF
        rewrite  "apps/web/templates/books/show.html.erb", <<-EOF
<h1><%= book.title %></h1>
EOF

        server do
          visit "/books/1"
          expect(page).to have_content("Learn Hanami")
        end
      end
    end
  end

  context "--host" do
    it "starts on given host" do
      with_project do
        server(host: '127.0.0.1') do
          visit "/"

          expect(page).to have_title("Hanami | The web, with simplicity")
        end
      end
    end

    xit "fails when missing" do
      with_project do
        server(host: nil)

        expect(exitstatus).to eq(1)
      end
    end
  end

  context "--port" do
    it "starts on given port" do
      with_project do
        server(port: 1982) do
          visit "/"

          expect(page).to have_title("Hanami | The web, with simplicity")
        end
      end
    end

    xit "fails when missing" do
      with_project do
        server(port: nil)

        expect(exitstatus).to eq(1)
      end
    end
  end

  context "environment" do
    it "starts with given environment" do
      with_project do
        generate "action web home#index --url=/"

        rewrite "apps/web/controllers/home/index.rb", <<-EOF
module Web::Controllers::Home
  class Index
    include Web::Action

    def call(params)
      self.body = Hanami.env
    end
  end
end
EOF

        RSpec::Support::Env['HANAMI_ENV']   = env = 'production'
        RSpec::Support::Env['DATABASE_URL'] = "file://#{Pathname.new('db').join('bookshelf')}"

        server do
          visit "/"

          expect(page).to have_content(env)
        end
      end
    end

    xit "fails when missing" do
      with_project do
        server(environment: nil)

        expect(exitstatus).to eq(1)
      end
    end
  end

  context "puma" do
    it "starts" do
      with_project('bookshelf_server_puma', server: :puma) do
        server do
          visit "/"

          expect(page).to have_title("Hanami | The web, with simplicity")
        end
      end
    end
  end

  context "unicorn" do
    it "starts" do
      with_project('bookshelf_server_unicorn', server: :unicorn) do
        server do
          visit "/"

          expect(page).to have_title("Hanami | The web, with simplicity")
        end
      end
    end
  end

  context "code reloading" do
    it "reloads templates code" do
      with_project do
        server do
          visit "/"

          expect(page).to have_title("Hanami | The web, with simplicity")
          generate "action web home#index --url=/"

          rewrite "apps/web/templates/home/index.html.erb", <<-EOF
<h1>Hello, World!</h1>
EOF

          visit "/"
          expect(page).to have_title("Web")
          expect(page).to have_content("Hello, World!")
        end
      end
    end

    it "reloads view" do
      with_project do
        server do
          visit "/"

          expect(page).to have_title("Hanami | The web, with simplicity")
          generate "action web home#index --url=/"

          rewrite "apps/web/views/home/index.rb", <<-EOF
module Web::Views::Home
  class Index
    include Web::View

    def greeting
      "Ciao!"
    end
  end
end
EOF

          rewrite "apps/web/templates/home/index.html.erb", <<-EOF
<%= greeting %>
EOF

          visit "/"
          expect(page).to have_title("Web")
          expect(page).to have_content("Ciao!")
        end
      end
    end

    it "reloads action" do
      with_project do
        server do
          visit "/"

          expect(page).to have_title("Hanami | The web, with simplicity")
          generate "action web home#index --url=/"

          rewrite "apps/web/controllers/home/index.rb", <<-EOF
module Web::Controllers::Home
  class Index
    include Web::Action

    def call(params)
      self.body = "Hi!"
    end
  end
end
EOF

          visit "/"
          expect(page).to have_content("Hi!")
        end
      end
    end

    xit "reloads asset" do
      with_project do
        server do
          write "apps/web/assets/stylesheets/style.css", <<-EOF
body { background-color: #fff; }
EOF

          visit "/assets/style.css"
          expect(page).to have_content("#fff")

          rewrite "apps/web/assets/stylesheets/style.css", <<-EOF
body { background-color: #333; }
EOF

          visit "/assets/style.css"
          expect(page).to have_content("#333")
        end
      end
    end
  end

  context "without code reloading" do
    it "doesn't reload code" do
      with_project do
        server("no-code-reloading" => nil) do
          visit "/"

          expect(page).to have_title("Hanami | The web, with simplicity")
          generate "action web home#index --url=/"

          visit "/"
          expect(page).to have_title("Hanami | The web, with simplicity")
        end
      end
    end
  end

  private

  def setup_model(project) # rubocop:disable Metrics/MethodLength
    generate_model     "book"
    generate_migration "create_books", <<-EOF
Hanami::Model.migration do
  change do
    create_table :books do
      primary_key :id
      column :title, String
    end
  end
end
EOF

    # FIXME: remove when we will integrate hanami-model 0.7
    entity("book", project, :title)

    # FIXME: remove when we will integrate hanami-model 0.7
    mapping project, <<-END
    collection :books do
      entity     Book
      repository BookRepository

      attribute :id,    Integer
      attribute :title, String
    end
END

    migrate
  end
end
