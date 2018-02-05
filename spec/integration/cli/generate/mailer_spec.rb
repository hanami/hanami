RSpec.describe "hanami generate", type: :integration do
  describe 'mailer' do
    context 'generates a new mailer' do
      let(:output) do
        ["create  lib/bookshelf_generate_mailer/mailers/welcome.rb",
         "create  spec/bookshelf_generate_mailer/mailers/welcome_spec.rb",
         "create  lib/bookshelf_generate_mailer/mailers/templates/welcome.txt.erb",
         "create  lib/bookshelf_generate_mailer/mailers/templates/welcome.html.erb"]
      end

      it 'generate the mailer files' do
        with_project('bookshelf_generate_mailer', test: 'rspec') do
          run_command "hanami generate mailer welcome", output
          #
          # lib/bookshelf_generate_mailer/mailers/welcome.rb
          #
          expect('lib/bookshelf_generate_mailer/mailers/welcome.rb').to have_file_content <<-END
class Mailers::Welcome
  include Hanami::Mailer

  from    '<from>'
  to      '<to>'
  subject 'Hello'
end
END

          expect('lib/bookshelf_generate_mailer/mailers/templates/welcome.txt.erb').to have_file_content ''
          expect('lib/bookshelf_generate_mailer/mailers/templates/welcome.html.erb').to have_file_content ''
        end
      end

      it 'generates a proper minitest file' do
        with_project('bookshelf_generate_mailer', test: 'minitest') do
          run_command "hanami generate mailer welcome", output
          #
          # spec/bookshelf_generate_mailer/mailers/welcome_spec.rb
          #
          expect('spec/bookshelf_generate_mailer/mailers/welcome_spec.rb').to have_file_content <<-END
require_relative '../../spec_helper'

describe Mailers::Welcome do
  it 'delivers email' do
    mail = Mailers::Welcome.deliver
  end
end
END
        end
      end

      it 'generates a proper RSpec file' do
        with_project('bookshelf_generate_mailer', test: 'rspec') do
          run_command "hanami generate mailer welcome", output
          #
          # spec/bookshelf_generate_mailer/mailers/welcome_spec.rb
          #
          expect('spec/bookshelf_generate_mailer/mailers/welcome_spec.rb').to have_file_content <<-END
RSpec.describe Mailers::Welcome, type: :mailer do
  it 'delivers email' do
    mail = Mailers::Welcome.deliver
  end
end
END
        end
      end
    end

    it 'generates mailer with options from, to and subject with single quotes' do
      with_project('bookshelf_generate_mailer_with_options') do
        output = [
          "create  spec/bookshelf_generate_mailer_with_options/mailers/welcome_spec.rb",
          "create  lib/bookshelf_generate_mailer_with_options/mailers/welcome.rb",
          "create  lib/bookshelf_generate_mailer_with_options/mailers/templates/welcome.txt.erb",
          "create  lib/bookshelf_generate_mailer_with_options/mailers/templates/welcome.html.erb"
        ]

        run_command "hanami generate mailer welcome --from=\"'mail@example.com'\" --to=\"'user@example.com'\" --subject=\"'Let\'s start'\"", output

        expect('lib/bookshelf_generate_mailer_with_options/mailers/welcome.rb').to have_file_content <<-END
class Mailers::Welcome
  include Hanami::Mailer

  from    'mail@example.com'
  to      'user@example.com'
  subject 'Let\'s start'
end
END
      end
    end

    it 'generates mailer with options from, to and subject with double quotes' do
      with_project('bookshelf_generate_mailer_with_options') do
        output = [
          "create  spec/bookshelf_generate_mailer_with_options/mailers/welcome_spec.rb",
          "create  lib/bookshelf_generate_mailer_with_options/mailers/welcome.rb",
          "create  lib/bookshelf_generate_mailer_with_options/mailers/templates/welcome.txt.erb",
          "create  lib/bookshelf_generate_mailer_with_options/mailers/templates/welcome.html.erb"
        ]

        run_command "hanami generate mailer welcome --from='\"mail@example.com\"' --to='\"user@example.com\"' --subject='\"Come on \"Folks\"\"'", output

        expect('lib/bookshelf_generate_mailer_with_options/mailers/welcome.rb').to have_file_content <<-END
class Mailers::Welcome
  include Hanami::Mailer

  from    'mail@example.com'
  to      'user@example.com'
  subject 'Come on \"Folks\"'
end
END
      end
    end

    it 'generates mailer with options from, to and subject without quotes' do
      with_project('bookshelf_generate_mailer_with_options') do
        output = [
          "create  spec/bookshelf_generate_mailer_with_options/mailers/welcome_spec.rb",
          "create  lib/bookshelf_generate_mailer_with_options/mailers/welcome.rb",
          "create  lib/bookshelf_generate_mailer_with_options/mailers/templates/welcome.txt.erb",
          "create  lib/bookshelf_generate_mailer_with_options/mailers/templates/welcome.html.erb"
        ]

        run_command "hanami generate mailer welcome --from=mail@example.com --to=user@example.com --subject=Welcome", output

        expect('lib/bookshelf_generate_mailer_with_options/mailers/welcome.rb').to have_file_content <<-END
class Mailers::Welcome
  include Hanami::Mailer

  from    'mail@example.com'
  to      'user@example.com'
  subject 'Welcome'
end
END
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

    it 'prints help message' do
      with_project do
        output = <<-OUT
Command:
  hanami generate mailer

Usage:
  hanami generate mailer MAILER

Description:
  Generate a mailer

Arguments:
  MAILER              	# REQUIRED The mailer name (eg. `welcome`)

Options:
  --from=VALUE                    	# The default `from` field of the mail
  --to=VALUE                      	# The default `to` field of the mail
  --subject=VALUE                 	# The mail subject
  --help, -h                      	# Print this help

Examples:
  hanami generate mailer welcome                                         # Basic usage
  hanami generate mailer welcome --from="noreply@example.com"            # Generate with default `from` value
  hanami generate mailer announcement --to="users@example.com"           # Generate with default `to` value
  hanami generate mailer forgot_password --subject="Your password reset" # Generate with default `subject`
OUT

        run_command 'hanami generate mailer --help', output
      end
    end
  end
end
