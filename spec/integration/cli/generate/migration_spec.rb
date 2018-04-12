RSpec.describe "hanami generate", type: :integration do
  describe "migration" do
    context "with migration name" do
      it_behaves_like "a new migration" do
        let(:input) { "users" }
      end
    end

    context "with underscored name" do
      it_behaves_like "a new migration" do
        let(:input) { "create_users" }
      end
    end

    context "with dashed name" do
      it_behaves_like "a new migration" do
        let(:input) { "add-verified-at-to-users" }
      end
    end

    context "with camel case app name" do
      it_behaves_like "a new migration" do
        let(:input) { "AddUniqueIndexUsersEmail" }
      end
    end

    context "with missing argument" do
      it "fails" do
        with_project('bookshelf_generate_migration_missing_arguments') do
          output = <<-END
ERROR: "hanami generate migration" was called with no arguments
Usage: "hanami generate migration MIGRATION"
END
          run_command "hanami generate migration", output, exit_status: 1
        end
      end
    end

    it 'prints help message' do
      with_project do
        banner = <<-OUT
Command:
  hanami generate migration

Usage:
  hanami generate migration MIGRATION

Description:
  Generate a migration

Arguments:
  MIGRATION           	# REQUIRED The migration name (eg. `create_users`)

Options:
  --help, -h                      	# Print this help

Examples:
OUT

        output = [
          banner,
          %r{  hanami generate migration create_users # Generate `db/migrations/[\d]{14}_create_users.rb`},
        ]

        run_command 'hanami generate migration --help', output
      end
    end
  end # migration
end
