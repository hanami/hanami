RSpec.describe "hanami db", type: :cli do
  describe "create" do
    it "creates database" do
      project = "bookshelf_db_create"

      with_project(project) do
        hanami "db create"

        db = Pathname.new("db").join("#{project}_development.sqlite").to_s
        expect(db).to be_an_existing_file
      end
    end

    it "doesn't create in production" do
      project = "bookshelf_db_create_production"

      with_project(project) do
        RSpec::Support::Env['HANAMI_ENV'] = 'production'
        hanami "db create"

        expect(exitstatus).to eq(1)

        db = Pathname.new("db").join("#{project}.sqlite").to_s
        expect(db).to_not be_an_existing_file
      end
    end

    it 'prints help message' do
      output = <<-OUT
      Usage:
        hanami db create

      Options:
        [--environment=ENVIRONMENT]  # Path to environment configuration (config/environment.rb)

      Create database for current environment
OUT

      run_command 'hanami db create --help', output
    end
  end
end
