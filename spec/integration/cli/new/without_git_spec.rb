RSpec.describe "hanami new", type: :cli do
  context "when git is not available" do
    it "generates project without .git directory" do
      project = 'bookshelf_hanami_without_git'
      output  = <<-OUT
        create  .hanamirc
        create  .env.development
        create  .env.test
        create  Gemfile
        create  config.ru
        create  config/environment.rb
        create  lib/#{project}.rb
        create  public/.keep
        create  config/initializers/.keep
        create  lib/#{project}/entities/.keep
        create  lib/#{project}/repositories/.keep
        create  lib/#{project}/mailers/.keep
        create  lib/#{project}/mailers/templates/.keep
        create  spec/#{project}/entities/.keep
        create  spec/#{project}/repositories/.keep
        create  spec/#{project}/mailers/.keep
        create  spec/support/.keep
        create  db/migrations/.keep
        create  Rakefile
        create  spec/spec_helper.rb
        create  spec/features_helper.rb
        create  db/schema.sql
        create  apps/web/application.rb
        create  apps/web/config/routes.rb
        create  apps/web/views/application_layout.rb
        create  apps/web/templates/application.html.erb
        create  apps/web/assets/favicon.ico
        create  apps/web/controllers/.keep
        create  apps/web/assets/images/.keep
        create  apps/web/assets/javascripts/.keep
        create  apps/web/assets/stylesheets/.keep
        create  spec/web/features/.keep
        create  spec/web/controllers/.keep
        create  spec/web/views/.keep
        insert  config/environment.rb
        insert  config/environment.rb
        append  .env.development
        append  .env.test
OUT

      without_command('git') do
        run_command "hanami new #{project}", output
      end

      within_project_directory(project) do
        expect(exist?('.git')).to be false
        expect(exist?('.gitignore')).to be false
      end
    end
  end
end
