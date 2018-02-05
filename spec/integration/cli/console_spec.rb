RSpec.describe "hanami console", type: :integration do
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

    it "starts console with --engine option" do
      with_project("bookshelf_console_irb", console: :irb) do
        console(" --engine=irb") do |input, _, _|
          input.puts("Hanami::VERSION")
          input.puts("exit")
        end

        expect(out).to include(Hanami::VERSION)
      end
    end

    it "starts console without hanami-model" do
      project_without_hanami_model("bookshelf", gems: ['dry-struct'], console: :irb) do
        write "lib/entities/access_token.rb", <<-EOF
require 'dry-struct'
require 'securerandom'

module Types
  include Dry::Types.module
end

class AccessToken < Dry::Struct
  attribute :id,     Types::String.default { SecureRandom.uuid }
  attribute :secret, Types::String
  attribute :digest, Types::String
end
EOF
        console do |input, _, _|
          input.puts("AccessToken.new(id: '1', secret: 'shh', digest: 'def')")
          input.puts("exit")
        end

        expect(out).to include('#<AccessToken id="1" secret="shh" digest="def">')
      end
    end
  end # irb

  xit "returns error when known engine isn't bundled" do
    with_project("bookshelf_console_irb", console: :irb) do
      output = "Missing gem for `pry' console engine. Please make sure to add it to `Gemfile'."
      run_command "hanami console --engine=pry", output, exit_status: 1
    end
  end

  it "returns error when unknown engine is requested" do
    with_project("bookshelf_console_irb", console: :irb) do
      output = "Unknown console engine: `foo'."
      run_command "hanami console --engine=foo", output, exit_status: 1
    end
  end

  it "prints help message" do
    with_project do
      output = <<-OUT
Command:
  hanami console

Usage:
  hanami console

Description:
  Starts Hanami console

Options:
  --engine=VALUE                  	# Force a specific console engine: (pry/ripl/irb)
  --help, -h                      	# Print this help

Examples:
  hanami console              # Uses the bundled engine
  hanami console --engine=pry # Force to use Pry
OUT

      run_command "hanami console --help", output
    end
  end

  # TODO: test with pry
  # TODO: test with ripl
end
