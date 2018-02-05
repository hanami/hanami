require 'pathname'

RSpec.describe "hanami destroy", type: :integration do
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

    it 'prints help message' do
      with_project do
        banner = <<-OUT
Command:
  hanami destroy migration

Usage:
  hanami destroy migration MIGRATION

Description:
  Destroy a migration

Arguments:
  MIGRATION           	# REQUIRED The migration name (eg. `create_users`)

Options:
  --help, -h                      	# Print this help

Examples:
OUT
        output = [
          banner,
          %r{  hanami destroy migration create_users # Destroy `db/migrations/[\d]{14}_create_users.rb`}
        ]

        run_command 'hanami destroy migration --help', output
      end
    end
  end # migration
end
