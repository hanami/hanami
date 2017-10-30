RSpec.describe "hanami new", type: :cli do
  describe "--run-bundler" do
    it "executes `bundler install` command after project generating" do
      project = 'bookshelf_run_bundler'

      run_command "hanami new #{project} --run-bundler"

      within_project_directory(project) do
        expect('Gemfile.lock').to be_an_existing_file
      end
    end
  end # run-bundler
end
