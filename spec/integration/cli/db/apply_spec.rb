RSpec.describe "hanami db", type: :integration do
  describe "apply" do
    it "migrates, dumps structure, deletes migrations" do
      with_project do
        versions = generate_migrations

        hanami "db apply"

        hanami "db version"
        expect(out).to include(versions.last.to_s)

        db         = Pathname.new('db')
        schema     = db.join('schema.sql').to_s
        migrations = db.join('migrations')

        expect(schema).to have_file_content <<-SQL
CREATE TABLE `schema_migrations` (`filename` varchar(255) NOT NULL PRIMARY KEY);
CREATE TABLE `users` (`id` integer NOT NULL PRIMARY KEY AUTOINCREMENT, `name` varchar(255), `age` integer);
INSERT INTO "schema_migrations" VALUES('#{versions.first}_create_users.rb');
INSERT INTO "schema_migrations" VALUES('#{versions.last}_add_age_to_users.rb');
SQL

        expect(migrations.children).to be_empty
      end
    end

    it "prints help message" do
      with_project do
        output = <<-OUT
Command:
  hanami db apply

Usage:
  hanami db apply

Description:
  Migrate, dump the SQL schema, and delete the migrations (experimental)

Options:
  --help, -h                      	# Print this help
OUT

        run_command "hanami db apply --help", output
      end
    end
  end
end
