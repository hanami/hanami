RSpec.describe "Rake: db:migrate", type: :integration do
  context "with hanami-model" do
    it "migrates" do
      project = "bookshelf_rake_db_migrate"

      with_project(project) do
        generate_migrations

        hanami "db create"
        bundle_exec "rake db:migrate"

        db = Pathname.new("db").join("#{project}_development.sqlite")

        version = `sqlite3 #{db} "SELECT filename FROM schema_migrations ORDER BY filename DESC LIMIT 1"`
        expect(version).to include("add_age_to_users")
      end
    end

    it "exit the parent process with the child exit status" do
      with_project do
        FileUtils.rm_rf("db")

        bundle_exec "rake db:migrate"
        expect(exitstatus).to be(1)
      end
    end
  end
end
