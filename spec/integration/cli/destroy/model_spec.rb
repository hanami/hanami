require 'pathname'

RSpec.describe "hanami destroy", type: :integration do
  describe "model" do
    it "destroys model" do
      with_project do
        generate "model user"
        migration = Dir.glob(Pathname.new("db").join("migrations", "*_create_users.rb")).first.to_s

        output = [
          "remove  spec/bookshelf/repositories/user_repository_spec.rb",
          "remove  spec/bookshelf/entities/user_spec.rb",
          "remove  lib/bookshelf/repositories/user_repository.rb",
          "remove  lib/bookshelf/entities/user.rb"
        ]

        run_command "hanami destroy model user", output

        expect(migration).to be_an_existing_file

        expect("lib/bookshelf/entities/user.rb").to_not                      be_an_existing_file
        expect("lib/bookshelf/repositories/user_repository.rb").to_not       be_an_existing_file
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
          "remove  spec/bookshelf/repositories/user_repository_spec.rb",
          "remove  spec/bookshelf/entities/user_spec.rb",
          "remove  lib/bookshelf/repositories/user_repository.rb",
          "remove  lib/bookshelf/entities/user.rb"
        ]

        run_command "hanami destroy model user", output
      end
    end

    it "fails with missing argument" do
      with_project do
        output = <<-OUT
ERROR: "hanami destroy model" was called with no arguments
Usage: "hanami destroy model MODEL"
OUT

        run_command "hanami destroy model", output, exit_status: 1
      end
    end

    xit 'prints help message' do
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

    it "fails with unknown model" do
      with_project do
        output = <<-OUT
cannot find `unknown' model. Please have a look at `lib/bookshelf/entities' directory to find an existing model.
OUT

        run_command "hanami destroy model unknown", output, exit_status: 1
      end
    end

    it 'prints help message' do
      with_project do
        output = <<-OUT
Command:
  hanami destroy model

Usage:
  hanami destroy model MODEL

Description:
  Destroy a model

Arguments:
  MODEL               	# REQUIRED The model name (eg. `user`)

Options:
  --help, -h                      	# Print this help

Examples:
  hanami destroy model user # Destroy `User` entity and `UserRepository` repository
OUT

        run_command 'hanami destroy model --help', output
      end
    end
  end # model
end
