require 'pathname'

RSpec.describe "hanami destroy", type: :cli do
  describe "model" do
    it "destroys model" do
      with_project do
        generate "model user"
        _migration = Dir.glob(Pathname.new("db").join("migrations", "*_create_users.rb")).first.to_s

        output = [
          "remove  lib/bookshelf/entities/user.rb",
          "remove  lib/bookshelf/repositories/user_repository.rb",
          # FIXME: with Hanami 1.1
          # "remove  #{migration}",
          "remove  spec/bookshelf/entities/user_spec.rb",
          "remove  spec/bookshelf/repositories/user_repository_spec.rb"
        ]

        run_command "hanami destroy model user", output

        expect("lib/bookshelf/entities/user.rb").to_not                      be_an_existing_file
        expect("lib/bookshelf/repositories/user_repository.rb").to_not       be_an_existing_file
        expect("spec/bookshelf/entities/user_spec.rb").to_not                be_an_existing_file
        expect("spec/bookshelf/repositories/user_repository_spec.rb").to_not be_an_existing_file
      end
    end

    it "fails with missing argument" do
      with_project do
        output = <<-OUT
ERROR: "hanami model" was called with no arguments
Usage: "hanami model NAME"
OUT
        run_command "hanami destroy model", output
      end
    end

    # xit "fails with unknown model" do
    #   with_project do
    #     output = <<-OUT
# ERROR: "hanami model" was called with no arguments
# Usage: "hanami model NAME"
# OUT
    #     run_command "hanami destroy model create_unknowns", output
    #   end
    # end
  end # model
end
