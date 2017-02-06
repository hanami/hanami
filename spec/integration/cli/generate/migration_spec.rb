RSpec.describe "hanami generate", type: :cli do
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
ERROR: "hanami migration" was called with no arguments
Usage: "hanami generate migration NAME"
END
          run_command "hanami generate migration", output # , exit_status: 1 FIXME: Thor exit with 0
        end
      end
    end
  end # migration
end
