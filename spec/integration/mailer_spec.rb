RSpec.describe "Mailer", type: :integration do
  it "use a mailer" do
    with_project do
      generate "mailer welcome"
      write "lib/bookshelf/mailers/default_user.rb", <<-EOF
module Mailers
  module DefaultUser
    def user_name
      "Alfonso"
    end
  end
end
EOF

      replace "config/environment.rb", "delivery :test", <<-EOF
    delivery :test

    prepare do
      include Mailers::DefaultUser
    end
EOF

      console do |input, _, _|
        input.puts("Mailers::Welcome.new.user_name")
      end

      expect(out).to include("Alfonso")
    end
  end
end
