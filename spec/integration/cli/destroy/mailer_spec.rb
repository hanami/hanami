RSpec.describe "hanami destroy", type: :cli do
  describe 'mailer' do
    context 'destroy a mailer' do
      let(:output) do
        ["remove  spec/bookshelf_generate_mailer/mailers/welcome_spec.rb",
         "remove  lib/bookshelf_generate_mailer/mailers/templates/welcome.html.erb",
         "remove  lib/bookshelf_generate_mailer/mailers/templates/welcome.txt.erb",
         "remove  lib/bookshelf_generate_mailer/mailers/welcome.rb"]
      end

      it 'generate the mailer files' do
        with_project('bookshelf_generate_mailer', test: 'rspec') do
          generate "mailer welcome"

          run_command "hanami destroy mailer welcome", output

          expect('spec/bookshelf_generate_mailer/mailers/welcome_spec.rb').to_not           be_an_existing_file
          expect('lib/bookshelf_generate_mailer/mailers/templates/welcome.html.erb').to_not be_an_existing_file
          expect('lib/bookshelf_generate_mailer/mailers/templates/welcome.txt.erb').to_not  be_an_existing_file
          expect('lib/bookshelf_generate_mailer/mailers/welcome.rb').to_not                 be_an_existing_file
        end
      end
    end

    it "fails with missing arguments" do
      with_project('bookshelf_generate_mailer_without_args') do
        output = <<-OUT
ERROR: "hanami generate mailer" was called with no arguments
Usage: "hanami generate mailer MAILER"
OUT

        run_command "hanami generate mailer", output, exit_status: 1
      end
    end

    it "fails with unknown mailer" do
      with_project do
        output = <<-OUT
cannot find `unknown' mailer. Please have a look at `lib/bookshelf/mailers' directory to find an existing mailer.
OUT

        run_command "hanami destroy mailer unknown", output, exit_status: 1
      end
    end
  end
end
