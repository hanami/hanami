RSpec.describe "hanami new", type: :cli do
  describe "--hanami-head" do
    it "generates project" do
      project = 'bookshelf_hanami_head'

      run_command "hanami new #{project} --hanami-head"

      within_project_directory(project) do
        #
        # Gemfile
        #
        expect('Gemfile').to have_file_content(%r{gem 'hanami-utils',       require: false, github: 'hanami/utils'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-router',      require: false, github: 'hanami/router'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-validations', require: false, github: 'hanami/validations'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-helpers',     require: false, github: 'hanami/helpers'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-controller',  require: false, github: 'hanami/controller'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-view',        require: false, github: 'hanami/view'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-model',       require: false, github: 'hanami/model'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-mailer',      require: false, github: 'hanami/mailer'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami-assets',      require: false, github: 'hanami/assets'})
        expect('Gemfile').to have_file_content(%r{gem 'hanami',                             github: 'hanami/hanami'})
      end
    end
  end # hanami-head
end
