require 'hanami/utils/string'

RSpec.describe "hanami generate", type: :cli do
  describe "model" do
    context "with model name" do
      it_behaves_like "a new model" do
        let(:input) { "user" }
      end
    end

    context "with underscored name" do
      it_behaves_like "a new model" do
        let(:input) { "discounted_book" }
      end
    end

    context "with dashed name" do
      it_behaves_like "a new model" do
        let(:input) { "user-event" }
      end
    end

    context "with camel case name" do
      it_behaves_like "a new model" do
        let(:input) { "VerifiedUser" }
      end
    end

    context "with missing argument" do
      it "fails" do
        with_project('bookshelf_generate_model_missing_arguments') do
          output = <<-END
ERROR: "hanami generate model" was called with no arguments
Usage: "hanami generate model NAME"
END
          run_command "hanami generate model", output # , exit_status: 1 FIXME: Thor exit with 0
        end
      end
    end

    context "with skip-migration" do
      it "doesn't create a migration file" do
        model_name = "user"
        table_name = "users"
        project = "bookshelf_generate_model_skip_migration"
        with_project(project) do
          run_command "hanami generate model #{model_name} --skip-migration"
          #
          # db/migrations/<timestamp>_create_<models>.rb
          #
          migrations = Pathname.new('db').join('migrations').children
          file       = migrations.find do |child|
            child.to_s.include?("create_#{table_name}")
          end

          expect(file).to be_nil, "Expected to not find a migration matching: create_#{table_name}. Found #{file && file.to_s}"
        end
      end
    end

    context "minitest" do
      it "generates model" do
        project = "bookshelf_generate_model_minitest"

        with_project(project, test: :minitest) do
          model      = "book"
          class_name = Hanami::Utils::String.new(model).classify
          output     = [
            "create  spec/#{project}/entities/#{model}_spec.rb",
            "create  spec/#{project}/repositories/#{model}_repository_spec.rb"
          ]

          run_command "hanami generate model #{model}", output

          #
          # spec/<project>/entities/<model>_spec.rb
          #
          expect("spec/#{project}/entities/#{model}_spec.rb").to have_file_content <<-END
require_relative '../../spec_helper'

describe #{class_name} do
  # place your tests here
end
END

          #
          # spec/<project>/repositories/<model>_repository_spec.rb
          #
          expect("spec/#{project}/repositories/#{model}_repository_spec.rb").to have_file_content <<-END
require_relative '../../spec_helper'

describe #{class_name}Repository do
  # place your tests here
end
END
        end
      end
    end # minitest

    context "rspec" do
      it "generates model" do
        project = "bookshelf_generate_model_rspec"

        with_project(project, test: :rspec) do
          model      = "book"
          class_name = Hanami::Utils::String.new(model).classify
          output     = [
            "create  spec/#{project}/entities/#{model}_spec.rb",
            "create  spec/#{project}/repositories/#{model}_repository_spec.rb"
          ]

          run_command "hanami generate model #{model}", output

          #
          # spec/<project>/entities/<model>_spec.rb
          #
          expect("spec/#{project}/entities/#{model}_spec.rb").to have_file_content <<-END
RSpec.describe #{class_name} do
  # place your tests here
end
END

          #
          # spec/<project>/repositories/<model>_repository_spec.rb
          #
          expect("spec/#{project}/repositories/#{model}_repository_spec.rb").to have_file_content <<-END
RSpec.describe BookRepository do
  # place your tests here
end
END
        end
      end
    end # rspec
  end # migration
end
