RSpec.describe "action validations", type: :integration do
  let(:project_name) { "bookshelf" }

  it "validates incoming data" do
    with_project(project_name) do
      generate_model_and_prepare_database
      generate_action

      server do
        post "/books", book: { title: "Hanami book", author: "Hanami Team" }
      end

      expect(last_response.status).to be(204)
    end
  end

  it "rejects invalid data" do
    with_project(project_name) do
      generate_model_and_prepare_database
      generate_action

      server do
        post "/books", book: { title: "", author: 23 }
      end

      expect(last_response.status).to be(422)
    end
  end

  private

  def generate_model_and_prepare_database
    generate_model "book"
    generate_migration "create_books", <<-EOF
Hanami::Model.migration do
  change do
    create_table :books do
      primary_key :id
      column :title, String
      column :author, String
    end
  end
end
    EOF

    hanami "db prepare"
  end

  def generate_action
    generate "action web books#create --url=/books --method=POST"

    rewrite "apps/web/controllers/books/create.rb", <<-EOF
module Web
  module Controllers
    module Books
      class Create
        include Web::Action

        expose :book

        params do
          required(:book).schema do
            required(:title).filled(:str?)
            required(:author).filled(:str?)
          end
        end

        def call(params)
          if params.valid?
            @book = BookRepository.new.create(params[:book])

            self.status = 204
          else
            self.status = 422
            self.body = params.errors.to_h.inspect
          end
        end
      end
    end
  end
end
EOF
  end
end
