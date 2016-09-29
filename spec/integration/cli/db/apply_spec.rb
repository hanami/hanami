RSpec.describe "hanami db", type: :cli do
  describe "apply" do
    it "migrates, dumps structure, deletes migrations" do
      project = "bookshelf_db_apply"

      with_project(project, database: :sqlite) do
        versions = generate_migrations

        hanami "db apply"

        hanami "db version"
        expect(out).to include(versions.last.to_s)

        db         = Pathname.new('db')
        _schema    = db.join('schema.sql').to_s
        migrations = db.join('migrations')

# rubocop:disable Style/CommentIndentation
#       expect(schema).to have_file_content <<-SQL
# CREATE TABLE `schema_migrations` (`filename` varchar(255) NOT NULL PRIMARY KEY);
# CREATE TABLE `users` (`id` integer NOT NULL PRIMARY KEY AUTOINCREMENT, `name` varchar(255), `age` integer);
# INSERT INTO "schema_migrations" VALUES('#{versions.first}_create_users.rb');
# INSERT INTO "schema_migrations" VALUES('#{versions.last}_add_age_to_users.rb');
# SQL
# rubocop:enable Style/CommentIndentation

        expect(migrations.children).to be_empty
      end
    end
  end
end
