require 'hanami/utils/string'

RSpec.shared_examples "a new project" do
  let(:project) { Hanami::Utils::String.new(input).underscore.to_s }

  it 'generates vanilla project' do
    run_command "hanami new #{input}"

    [
      "create  lib/#{project}.rb",
      "create  lib/#{project}/entities/.keep",
      "create  lib/#{project}/repositories/.keep",
      "create  lib/#{project}/mailers/.keep",
      "create  lib/#{project}/mailers/templates/.keep",
      "create  spec/#{project}/entities/.keep",
      "create  spec/#{project}/repositories/.keep",
      "create  spec/#{project}/mailers/.keep"
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
      expect('.env.development').to have_file_content(%r{DATABASE_URL="sqlite://db/#{project}_development.sqlite"})

      #
      # .env.test
      #
      expect('.env.test').to have_file_content(%r{DATABASE_URL="sqlite://db/#{project}_test.sqlite"})

      #
      # config/environment.rb
      #
      expect('config/environment.rb').to have_file_content %r{require_relative '../lib/#{project}'}

      #
      # lib/<project>.rb
      #
      expect("lib/#{project}.rb").to have_file_content <<-END
Hanami::Utils.require!("\#{__dir__}/#{project}")
END

      #
      # lib/<project>/entities/.keep
      #
      expect("lib/#{project}/entities/.keep").to be_an_existing_file

      #
      # lib/<project>/mailers/.keep
      #
      expect("lib/#{project}/mailers/.keep").to be_an_existing_file

      #
      # lib/<project>/mailers/templates/.keep
      #
      expect("lib/#{project}/mailers/templates/.keep").to be_an_existing_file

      #
      # spec/<project>/entities/.keep
      #
      expect("spec/#{project}/entities/.keep").to be_an_existing_file

      #
      # spec/<project>/repositories/.keep
      #
      expect("spec/#{project}/repositories/.keep").to be_an_existing_file

      #
      # spec/<project>/mailers/.keep
      #
      expect("spec/#{project}/mailers/.keep").to be_an_existing_file

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
end
