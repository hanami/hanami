RSpec.describe "hanami new", type: :integration do
  describe "--hanami-head" do
    it "generates project" do
      project = 'bookshelf_hanami_head'

      run_command "hanami new #{project} --hanami-head"

      within_project_directory(project) do
        #
        # Gemfile
        #
        expect('Gemfile').to have_file_content(%r{gem 'hanami-utils',       require: false, git: 'https://github.com/hanami/utils.git',       branch: 'develop'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-validations', require: false, git: 'https://github.com/hanami/validations.git', branch: 'develop'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-router',      require: false, git: 'https://github.com/hanami/router.git',      branch: 'develop'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-controller',  require: false, git: 'https://github.com/hanami/controller.git',  branch: 'develop'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-view',        require: false, git: 'https://github.com/hanami/view.git',        branch: 'develop'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-helpers',     require: false, git: 'https://github.com/hanami/helpers.git',     branch: 'develop'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-mailer',      require: false, git: 'https://github.com/hanami/mailer.git',      branch: 'develop'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-cli',         require: false, git: 'https://github.com/hanami/cli.git',         branch: 'develop'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-assets',      require: false, git: 'https://github.com/hanami/assets.git',      branch: 'develop'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-model',       require: false, git: 'https://github.com/hanami/model.git',       branch: 'develop'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami',                             git: 'https://github.com/hanami/hanami.git',      branch: 'develop'})
      end
    end
  end # hanami-head
end
