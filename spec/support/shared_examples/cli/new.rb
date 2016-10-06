require 'hanami/utils/string'

RSpec.shared_examples "a new project" do
  let(:project) { Hanami::Utils::String.new(input).underscore.to_s }

  it 'generates vanilla project' do
    run_command "hanami new #{input}"

    [
      "create  lib/#{project}.rb",
      "create  lib/#{project}/entities/.gitkeep",
      "create  lib/#{project}/repositories/.gitkeep",
      "create  lib/#{project}/mailers/.gitkeep",
      "create  lib/#{project}/mailers/templates/.gitkeep",
      "create  spec/#{project}/entities/.gitkeep",
      "create  spec/#{project}/repositories/.gitkeep",
      "create  spec/#{project}/mailers/.gitkeep"
    ].each do |output|
      expect(all_output).to match(/#{output}/)
    end

    within_project_directory(project) do
      #
      # .hanamirc
      #
      expect('.hanamirc').to have_file_content %r{project=#{project}}

      #
      # .env.development
      #
      expect('.env.development').to have_file_content(%r{DATABASE_URL="file:///db/#{project}_development"})

      #
      # .env.test
      #
      expect('.env.test').to have_file_content(%r{DATABASE_URL="file:///db/#{project}_test"})

      #
      # config/environment.rb
      #
      expect('config/environment.rb').to have_file_content %r{require_relative '../lib/#{project}'}

      #
      # lib/<project>.rb
      #
      expect("lib/#{project}.rb").to have_file_content <<-END
Dir["\#{__dir__}/#{project}/**/*.rb"].each { |file| require_relative file }
END

      #
      # lib/<project>/entities/.gitkeep
      #
      expect("lib/#{project}/entities/.gitkeep").to be_an_existing_file

      #
      # lib/<project>/mailers/.gitkeep
      #
      expect("lib/#{project}/mailers/.gitkeep").to be_an_existing_file

      #
      # lib/<project>/mailers/templates/.gitkeep
      #
      expect("lib/#{project}/mailers/templates/.gitkeep").to be_an_existing_file

      #
      # spec/<project>/entities/.gitkeep
      #
      expect("spec/#{project}/entities/.gitkeep").to be_an_existing_file

      #
      # spec/<project>/repositories/.gitkeep
      #
      expect("spec/#{project}/repositories/.gitkeep").to be_an_existing_file

      #
      # spec/<project>/mailers/.gitkeep
      #
      expect("spec/#{project}/mailers/.gitkeep").to be_an_existing_file

      #
      # .gitignore
      #
      expect(".gitignore").to have_file_content <<-END
/db/#{project}_development
/db/#{project}_test
/public/assets*
/tmp
END
    end
  end
end
