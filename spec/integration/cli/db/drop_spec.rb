RSpec.describe "hanami db", type: :integration do
  describe "drop" do
    it "drops database" do
      project = "bookshelf_db_drop"

      with_project(project) do
        db = Pathname.new("db").join("#{project}_development.sqlite").to_s

        hanami "db create"
        expect(db).to be_an_existing_file

        hanami "db drop"
        expect(db).to_not be_an_existing_file
      end
    end

    it "doesn't drop in production" do
      project = "bookshelf_db_drop_production"

      with_project(project) do
        RSpec::Support::Env['HANAMI_ENV'] = 'production'
        db = Pathname.new("db").join("#{project}.sqlite").to_s
        FileUtils.touch(db) # simulate existing database

        hanami "db drop"

        expect(exitstatus).to eq(1)
        expect(db).to be_an_existing_file
      end
    end

    it 'prints help message' do
      with_project do
        output = <<-OUT
Command:
  hanami db drop

Usage:
  hanami db drop

Description:
  Drop the database (only for development/test)

Options:
  --help, -h                      	# Print this help
OUT

        run_command 'hanami db drop --help', output
      end
    end
  end
end
