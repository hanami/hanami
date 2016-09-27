RSpec.describe "hanami console", type: :cli do
  context "irb" do
    let(:project) { "bookshelf_console_irb" }

    it "starts console" do
      with_project(project, database: :sqlite, console: :irb) do
        setup_model(project)

        console do |input, _, _|
          input.puts("Hanami::VERSION")
          input.puts("Web::Application")
          input.puts("Web::Routes")
          input.puts("BookRepository.all")
          input.puts("exit")
        end

        expect(out).to include(Hanami::VERSION)
        expect(out).to include("Web::Application")
        expect(out).to include("#<Hanami::Routes")
        expect(out).to include("[]")
      end
    end
  end # irb

  # TODO: test with pry
  # TODO: test with ripl

  private

  def setup_model(project) # rubocop:disable Metrics/MethodLength
    generate_model     "book"
    generate_migration "create_books", <<-EOF
Hanami::Model.migration do
  change do
    create_table :books do
      primary_key :id
      column :name, String
    end
  end
end
EOF

    # FIXME: remove when we will integrate hanami-model 0.7
    entity("book", project, :name)

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
