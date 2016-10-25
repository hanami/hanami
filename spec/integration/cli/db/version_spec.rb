RSpec.describe "hanami db", type: :cli do
  describe "version" do
    it "prints database version" do
      project = "bookshelf_db_version"

      with_project(project, database: :sqlite) do
        versions = generate_migrations

        hanami "db create"
        hanami "db migrate"
        hanami "db version"

        expect(out).to include(versions.last.to_s)
      end
    end
  end
end
