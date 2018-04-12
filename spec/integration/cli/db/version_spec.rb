RSpec.describe "hanami db", type: :integration do
  describe "version" do
    it "prints database version" do
      with_project do
        versions = generate_migrations

        hanami "db create"
        hanami "db migrate"
        hanami "db version"

        expect(out).to     include(versions.last.to_s)
        expect(out).to_not include("SELECT * FROM")
      end
    end

    it 'prints help message' do
      with_project do
        output = <<-OUT
Command:
  hanami db version

Usage:
  hanami db version

Description:
  Print the current migrated version

Options:
  --help, -h                      	# Print this help
OUT

        run_command 'hanami db version --help', output
      end
    end
  end
end
