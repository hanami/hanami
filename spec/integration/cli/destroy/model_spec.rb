require 'pathname'

RSpec.describe "hanami destroy", type: :cli do
  describe "model" do
    it "destroys model" do
      with_project do
        generate "model user"
        migration = Dir.glob(Pathname.new("db").join("migrations", "*_create_users.rb")).first.to_s

        output = [
          "remove  lib/bookshelf/entities/user.rb",
          "remove  lib/bookshelf/repositories/user_repository.rb",
          "remove  #{migration}",
          "remove  spec/bookshelf/entities/user_spec.rb",
          "remove  spec/bookshelf/repositories/user_repository_spec.rb"
        ]

        run_command "hanami destroy model user", output

        expect("lib/bookshelf/entities/user.rb").to_not                      be_an_existing_file
        expect("lib/bookshelf/repositories/user_repository.rb").to_not       be_an_existing_file
        expect(migration).to_not                                             be_an_existing_file
        expect("spec/bookshelf/entities/user_spec.rb").to_not                be_an_existing_file
        expect("spec/bookshelf/repositories/user_repository_spec.rb").to_not be_an_existing_file
      end
    end

    it "destroys model even if migration was deleted manually" do
      with_project do
        generate "model user"
        migration = Dir.glob(Pathname.new("db").join("migrations", "*_create_users.rb")).first.to_s

        run_simple "rm #{migration}"

        expect(migration).to_not be_an_existing_file

        output = [
          "remove  lib/bookshelf/entities/user.rb",
          "remove  lib/bookshelf/repositories/user_repository.rb",
          /remove.+_create_users\.rb/,
          "remove  spec/bookshelf/entities/user_spec.rb",
          "remove  spec/bookshelf/repositories/user_repository_spec.rb"
        ]

        run_command "hanami destroy model user", output
      end
    end

    it "fails with missing argument" do
      with_project do
        output = <<-OUT
ERROR: "hanami destroy model" was called with no arguments
Usage: "hanami destroy model NAME"
OUT
        run_command "hanami destroy model", output
      end
    end

    it 'prints help message' do
      with_project do
        output = <<-OUT
Usage:
  hanami destroy model NAME

Description:
  `hanami destroy model` will destroy an entity along with repository and \n  corresponding tests

  > $ hanami destroy model car
OUT

        run_command 'hanami destroy model --help', output
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
