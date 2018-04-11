RSpec.describe "hanami db", type: :integration do
  describe "prepare" do
    it "prepares database" do
      with_project do
        versions = generate_migrations

        hanami "db prepare"
        hanami "db version"

        expect(out).to include(versions.last.to_s)
      end
    end

    it 'prints help message' do
      with_project do
        output = <<-OUT
Command:
  hanami db prepare

Usage:
  hanami db prepare

Description:
  Drop, create, and migrate the database (only for development/test)

Options:
  --help, -h                      	# Print this help
OUT

        run_command 'hanami db prepare --help', output
      end
    end
  end
end
