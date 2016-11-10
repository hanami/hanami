RSpec.describe "hanami console", type: :cli do
  context "irb" do
    it "starts console" do
      with_project("bookshelf_console_irb", console: :irb) do
        setup_model

        console do |input, _, _|
          input.puts("Hanami::VERSION")
          input.puts("Web::Application")
          input.puts("Web.routes")
          input.puts("BookRepository.new.all.to_a")
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

  def setup_model # rubocop:disable Metrics/MethodLength
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

    migrate
  end
end
