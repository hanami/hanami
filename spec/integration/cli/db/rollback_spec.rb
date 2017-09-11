RSpec.describe "hanami db", type: :cli do
  describe "rollback" do
    it "rollbacks database" do
      project = "bookshelf_db_rollback"

      with_project(project) do
        generate_migrations

        hanami "db create"
        hanami "db migrate"
        hanami "db rollback"

        db = Pathname.new("db").join("#{project}_development.sqlite")

        users = `sqlite3 #{db} ".schema users"`
        expect(users).to include("CREATE TABLE `users`(`id` integer DEFAULT (NULL) NOT NULL PRIMARY KEY AUTOINCREMENT, `name` varchar(255) DEFAULT (NULL) NULL);")

        version = `sqlite3 #{db} "SELECT filename FROM schema_migrations ORDER BY filename DESC LIMIT 1"`
        expect(version).to_not include("add_age_to_users")
      end
    end

    it "rollbacks database using custom steps" do
      project = "bookshelf_db_migrate_custom_steps"

      with_project(project) do
        generate_migrations

        hanami "db create"
        hanami "db migrate"
        hanami "db rollback 2"

        db = Pathname.new("db").join("#{project}_development.sqlite")

        users = `sqlite3 #{db} ".schema users"`
        expect(users).to_not include("CREATE TABLE `users`(`id` integer DEFAULT (NULL) NOT NULL PRIMARY KEY AUTOINCREMENT, `name` varchar(255) DEFAULT (NULL) NULL);")

        version = `sqlite3 #{db} "SELECT filename FROM schema_migrations ORDER BY filename DESC LIMIT 1"`
        expect(version).to_not include("create_users")
      end
    end

    it 'prints help message' do
      with_project do
        output = <<-OUT
Command:
  hanami db rollback

Usage:
  hanami db rollback [STEPS]

Description:
  Rollback the database

Arguments:
  STEPS               	# Number of versions to rollback the database

Options:
  --help, -h                      	# Print this help

Examples:
  hanami db rollback   # Rollback lastest version
  hanami db rollback 2 # Rollbacks two versions
OUT
        run_command 'hanami db rollback --help', output
      end
    end
  end
end
