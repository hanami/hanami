RSpec.describe "hanami new", type: :cli do
  describe "--database" do
    context "postgres" do
      it "generates project" do
        project = 'bookshelf_postgresql'

        run_command "hanami new #{project} --database=postgres"

        [
          "create  db/migrations/.gitkeep",
          "create  db/schema.sql"
        ].each do |output|
          expect(all_output).to match(/#{output}/)
        end

        within_project_directory(project) do
          #
          # .env.development
          #
          development_url = Platform.match do
            engine(:ruby)  { "postgres://localhost/#{project}_development" }
            engine(:jruby) { "jdbc:postgres://localhost/#{project}_development" }
          end

          expect('.env.development').to have_file_content(%r{DATABASE_URL="#{development_url}"})

          #
          # .env.test
          #
          test_url = Platform.match do
            engine(:ruby)  { "postgres://localhost/#{project}_test" }
            engine(:jruby) { "jdbc:postgres://localhost/#{project}_test" }
          end

          expect('.env.test').to have_file_content(%r{DATABASE_URL="#{test_url}"})

          #
          # Gemfile
          #
          gem_name = Platform.match do
            engine(:ruby)  { "pg" }
            engine(:jruby) { "jdbc-postgres" }
          end

          expect('Gemfile').to have_file_content(%r{gem '#{gem_name}'})

          #
          # lib/<project>.rb
          #
          expect("lib/#{project}.rb").to have_file_content(%r{  adapter type: :sql, uri: ENV\['DATABASE_URL'\]})
          expect("lib/#{project}.rb").to have_file_content(%r{  migrations 'db/migrations'})
          expect("lib/#{project}.rb").to have_file_content(%r{  schema     'db/schema.sql'})

          #
          # db/migrations/.gitkeep
          #
          expect('db/migrations/.gitkeep').to be_an_existing_file

          #
          # db/schema.sql
          #
          expect('db/schema.sql').to be_an_existing_file

          #
          # .gitignore
          #
          expect(".gitignore").to have_file_content <<-END
/public/assets*
/tmp
          END
        end
      end
    end # postgres

    describe "sqlite" do
      it "generates project" do
        project = 'bookshelf_sqlite'

        run_command "hanami new #{project} --database=sqlite"

        [
          "create  db/migrations/.gitkeep",
          "create  db/schema.sql"
        ].each do |output|
          expect(all_output).to match(/#{output}/)
        end

        within_project_directory(project) do
          #
          # .env.development
          #
          development_url = Platform.match do
            engine(:ruby)  { "sqlite://db/#{project}_development.sqlite" }
            engine(:jruby) { "jdbc:sqlite://db/#{project}_development.sqlite" }
          end

          expect('.env.development').to have_file_content(%r{DATABASE_URL="#{development_url}"})

          #
          # .env.test
          #
          test_url = Platform.match do
            engine(:ruby)  { "sqlite://db/#{project}_test.sqlite" }
            engine(:jruby) { "jdbc:sqlite://db/#{project}_test.sqlite" }
          end

          expect('.env.test').to have_file_content(%r{DATABASE_URL="#{test_url}"})

          #
          # Gemfile
          #
          gem_name = Platform.match do
            engine(:ruby)  { "sqlite3" }
            engine(:jruby) { "jdbc-sqlite3" }
          end

          expect('Gemfile').to have_file_content(%r{gem '#{gem_name}'})

          #
          # lib/<project>.rb
          #
          expect("lib/#{project}.rb").to have_file_content(%r{  adapter type: :sql, uri: ENV\['DATABASE_URL'\]})
          expect("lib/#{project}.rb").to have_file_content(%r{  migrations 'db/migrations'})
          expect("lib/#{project}.rb").to have_file_content(%r{  schema     'db/schema.sql'})

          #
          # db/migrations/.gitkeep
          #
          expect('db/migrations/.gitkeep').to be_an_existing_file

          #
          # db/schema.sql
          #
          expect('db/schema.sql').to be_an_existing_file

          #
          # .gitignore
          #
          expect(".gitignore").to have_file_content <<-END
/db/*.sqlite
/public/assets*
/tmp
          END
        end
      end
    end # sqlite

    context "mysql" do
      it "generates project" do
        project = 'bookshelf_mysql'

        run_command "hanami new #{project} --database=mysql"

        [
          "create  db/migrations/.gitkeep",
          "create  db/schema.sql"
        ].each do |output|
          expect(all_output).to match(/#{output}/)
        end

        within_project_directory(project) do
          #
          # .env.development
          #
          development_url = Platform.match do
            engine(:ruby)  { "mysql2://localhost/#{project}_development" }
            engine(:jruby) { "jdbc:mysql://localhost/#{project}_development" }
          end

          expect('.env.development').to have_file_content(%r{DATABASE_URL="#{development_url}"})

          #
          # .env.test
          #
          test_url = Platform.match do
            engine(:ruby)  { "mysql2://localhost/#{project}_test" }
            engine(:jruby) { "jdbc:mysql://localhost/#{project}_test" }
          end

          expect('.env.test').to have_file_content(%r{DATABASE_URL="#{test_url}"})

          #
          # Gemfile
          #
          gem_name = Platform.match do
            engine(:ruby)  { "mysql2" }
            engine(:jruby) { "jdbc-mysql" }
          end

          expect('Gemfile').to have_file_content(%r{gem '#{gem_name}'})

          #
          # lib/<project>.rb
          #
          expect("lib/#{project}.rb").to have_file_content(%r{  adapter type: :sql, uri: ENV\['DATABASE_URL'\]})
          expect("lib/#{project}.rb").to have_file_content(%r{  migrations 'db/migrations'})
          expect("lib/#{project}.rb").to have_file_content(%r{  schema     'db/schema.sql'})

          #
          # db/migrations/.gitkeep
          #
          expect('db/migrations/.gitkeep').to be_an_existing_file

          #
          # db/schema.sql
          #
          expect('db/schema.sql').to be_an_existing_file

          #
          # .gitignore
          #
          expect(".gitignore").to have_file_content <<-END
/public/assets*
/tmp
          END
        end
      end
    end # mysql

    context "missing" do
      it "returns error" do
        output = "`' is not a valid database engine"

        run_command "hanami new bookshelf --database=", output, exit_status: 1
      end
    end # missing

    context "unknown" do
      it "returns error" do
        output = "`foo' is not a valid database engine"

        run_command "hanami new bookshelf --database=foo", output, exit_status: 1
      end
    end # unknown
  end # database
end
