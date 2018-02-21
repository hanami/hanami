RSpec.describe "hanami new", type: :integration do
  describe "--database" do
    context "postgres" do
      it "generates project" do
        project = 'bookshelf_postgresql'
        output  = [
          "create  db/migrations/.gitkeep",
          "create  db/schema.sql"
        ]

        run_command "hanami new #{project} --database=postgres", output

        within_project_directory(project) do
          #
          # .env.development
          #
          development_url = Platform.match do
            engine(:ruby)  { "postgresql://localhost/#{project}_development" }
            engine(:jruby) { "jdbc:postgresql://localhost/#{project}_development" }
          end

          expect('.env.development').to have_file_content(%r{DATABASE_URL="#{development_url}"})

          #
          # .env.test
          #
          test_url = Platform.match do
            engine(:ruby)  { "postgresql://localhost/#{project}_test" }
            engine(:jruby) { "jdbc:postgresql://localhost/#{project}_test" }
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
          # config/environment.rb
          #
          expect("config/environment.rb").to have_file_content(%r{  adapter :sql, ENV.fetch\('DATABASE_URL'\)})
          expect("config/environment.rb").to have_file_content(%r{  migrations 'db/migrations'})
          expect("config/environment.rb").to have_file_content(%r{  schema     'db/schema.sql'})

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
        output  = [
          "create  db/migrations/.gitkeep",
          "create  db/schema.sql"
        ]

        run_command "hanami new #{project} --database=sqlite", output

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
          # config/environment.rb
          #
          expect("config/environment.rb").to have_file_content(%r{  adapter :sql, ENV.fetch\('DATABASE_URL'\)})
          expect("config/environment.rb").to have_file_content(%r{  migrations 'db/migrations'})
          expect("config/environment.rb").to have_file_content(%r{  schema     'db/schema.sql'})

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
        output  = [
          "create  db/migrations/.gitkeep",
          "create  db/schema.sql"
        ]

        run_command "hanami new #{project} --database=mysql", output

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
          # config/environment.rb
          #
          expect("config/environment.rb").to have_file_content(%r{  adapter :sql, ENV.fetch\('DATABASE_URL'\)})
          expect("config/environment.rb").to have_file_content(%r{  migrations 'db/migrations'})
          expect("config/environment.rb").to have_file_content(%r{  schema     'db/schema.sql'})

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
