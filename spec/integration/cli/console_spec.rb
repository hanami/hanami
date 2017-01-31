RSpec.describe "hanami console", type: :cli do
  context "irb" do
    it "starts console" do
      project_name = "bookshelf_console_irb"
      with_project(project_name, console: :irb) do
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
        expect(out).to include("[#{project_name}] [INFO]")
        expect(out).to include("SELECT `id`, `title` FROM `books` ORDER BY `books`.`id`")
      end
    end
  end # irb

  # TODO: test with pry
  # TODO: test with ripl
end
