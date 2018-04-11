RSpec.describe "hanami db", type: :integration do
  describe "console" do
    it "starts database console" do
      with_project do
        generate_migrations
        hanami "db prepare"

        db_console do |input, _, _|
          input.puts('INSERT INTO users (id, name, age) VALUES(1, "Luca", 34);')
          input.puts('SELECT * FROM users;')
          input.puts('.quit')
        end

        expect(out).to include("1|Luca|34")
      end
    end

    it "prints help message" do
      with_project do
        output = <<-OUT
Command:
  hanami db console

Usage:
  hanami db console

Description:
  Starts a database console

Options:
  --help, -h                      	# Print this help
OUT

        run_command "hanami db console --help", output
      end
    end
  end
end
