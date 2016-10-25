RSpec.describe "hanami db", type: :cli do
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
  end
end
