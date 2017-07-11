require 'pathname'

RSpec.describe "hanami destroy", type: :cli do
  describe "migration" do
    it "destroys migration" do
      with_project do
        migration = Pathname.new("db").join("migrations", "20170127165331_create_users.rb").to_s
        File.open(migration, "wb+") { |f| f.write("migration") }

        output = [
          "remove  #{migration}"
        ]

        run_command "hanami destroy migration create_users", output

        expect(migration).to_not be_an_existing_file
      end
    end

    it "fails with missing argument" do
      with_project do
        output = <<-OUT
ERROR: "hanami destroy migration" was called with no arguments
Usage: "hanami destroy migration MIGRATION"
OUT
        run_command "hanami destroy migration", output, exit_status: 1
      end
    end

    it "fails with unknown migration" do
      with_project do
        output = <<-OUT
cannot find `create_unknowns'. Please have a look at `db/migrations' directory to find an existing migration
OUT
        run_command "hanami destroy migration create_unknowns", output, exit_status: 1
      end
    end
  end # migration
end
