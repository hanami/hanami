RSpec.describe "hanami generate", type: :cli do
  describe 'mailer' do
    it 'generates new mailer' do
      with_project('bookshelf_generate_mailer') do
        output = [
          "create  spec/bookshelf_generate_mailer/mailers/welcome_spec.rb",
          "create  lib/bookshelf_generate_mailer/mailers/welcome.rb",
          "create  lib/bookshelf_generate_mailer/mailers/templates/welcome.txt.erb",
          "create  lib/bookshelf_generate_mailer/mailers/templates/welcome.html.erb"
        ]

        run_command "hanami generate mailer welcome", output

        #
        # spec/bookshelf_generate_mailer/mailers/welcome_spec.rb
        #
        expect('spec/bookshelf_generate_mailer/mailers/welcome_spec.rb').to have_file_content <<-END
require 'spec_helper'

describe Mailers::Welcome do
  it 'delivers email' do
    mail = Mailers::Welcome.deliver
  end
end
END

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


    it "fails with missing arguments" do
      with_project('bookshelf_generate_mailer_without_args') do
        output = <<-OUT
ERROR: "hanami mailer" was called with no arguments
Usage: "hanami mailer NAME"
OUT

        run_command "hanami generate mailer", output
      end
    end

    it 'generates mailer with options from, to, subject' do
      with_project('bookshelf_generate_mailer_with_options') do
        output = [
          "create  spec/bookshelf_generate_mailer_with_options/mailers/welcome_spec.rb",
          "create  lib/bookshelf_generate_mailer_with_options/mailers/welcome.rb",
          "create  lib/bookshelf_generate_mailer_with_options/mailers/templates/welcome.txt.erb",
          "create  lib/bookshelf_generate_mailer_with_options/mailers/templates/welcome.html.erb"
        ]

        run_command "hanami generate mailer welcome --from=\"'mail@example.com'\" --to=\"'user@example.com'\" --subject=\"'Welcome'\"", output

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
  end
end
