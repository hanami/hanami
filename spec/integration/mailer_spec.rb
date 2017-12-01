RSpec.describe "Mailer", type: :cli do
  xit "use a mailer" do
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

      replace "config/environment.rb", "config.delivery_method = :test", <<-EOF
    config.delivery_method = :test

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
