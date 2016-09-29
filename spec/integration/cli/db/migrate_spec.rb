RSpec.describe "hanami db", type: :cli do
  describe "migrate" do
    it "migrates database" do
      project = "bookshelf_db_migrate"

      with_project(project, database: :sqlite) do
        generate_migrations

        hanami "db create"
        hanami "db migrate"

        db = Pathname.new("db").join("#{project}_development.sqlite")

        users = `sqlite3 #{db} ".schema users"`
        expect(users).to include("CREATE TABLE `users` (`id` integer NOT NULL PRIMARY KEY AUTOINCREMENT, `name` varchar(255), `age` integer);")

        version = `sqlite3 #{db} "SELECT filename FROM schema_migrations ORDER BY filename DESC LIMIT 1"`
        expect(version).to include("add_age_to_users")
      end
    end

    it "migrates database up to a version" do
      project = "bookshelf_db_migrate_up_to_version"

      with_project(project, database: :sqlite) do
        versions = generate_migrations

        hanami "db create"
        hanami "db migrate #{versions.first}"

        db = Pathname.new("db").join("#{project}_development.sqlite")

        users = `sqlite3 #{db} ".schema users"`
        expect(users).to include("CREATE TABLE `users` (`id` integer NOT NULL PRIMARY KEY AUTOINCREMENT, `name` varchar(255));")

        version = `sqlite3 #{db} "SELECT filename FROM schema_migrations ORDER BY filename DESC LIMIT 1"`
        expect(version).to include("create_users")
      end
    end

    it "migrates database down to a version" do
      project = "bookshelf_db_migrate_down_to_version"

      with_project(project, database: :sqlite) do
        versions = generate_migrations

        hanami "db create"
        hanami "db migrate" # up to latest version
        hanami "db migrate #{versions.first}"

        db = Pathname.new("db").join("#{project}_development.sqlite")

        users = `sqlite3 #{db} ".schema users"`
        expect(users).to include("CREATE TABLE `users`(`id` integer DEFAULT (NULL) NOT NULL PRIMARY KEY, `name` varchar(255) DEFAULT (NULL) NULL);")

        version = `sqlite3 #{db} "SELECT filename FROM schema_migrations ORDER BY filename DESC LIMIT 1"`
        expect(version).to include("create_users")
      end
    end

    it "migrates database down to 0" do
      project = "bookshelf_db_migrate_down_to_zero"

      with_project(project, database: :sqlite) do
        generate_migrations

        hanami "db create"
        hanami "db migrate" # up to latest version
        hanami "db migrate 0"

        db = Pathname.new("db").join("#{project}_development.sqlite")

        users = `sqlite3 #{db} ".schema users"`
        expect(users).to eq("")

        version = `sqlite3 #{db} "SELECT filename FROM schema_migrations ORDER BY filename DESC LIMIT 1"`
        expect(version).to eq("")
      end
    end
  end
end
