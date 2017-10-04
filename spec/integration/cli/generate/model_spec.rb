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
Usage: "hanami generate model MODEL"
END
          run_command "hanami generate model", output, exit_status: 1
        end
      end
    end

    context "with missing migrations directory" do
      it "will create directory and migration" do
        with_project do
          model_name = "book"
          directory  = Pathname.new("db").join("migrations")
          FileUtils.rm_rf(directory)

          run_command "hanami generate model #{model_name}"
          expect(directory).to be_directory

          migration = directory.children.find do |m|
            m.to_s.include?(model_name)
          end

          expect(migration).to_not be(nil)
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

    context 'with relation-name option' do
      let(:project)    { 'generate_model_with_relation_name' }
      let(:model_name) { 'stimulus' }
      let(:class_name) { 'Stimulus' }
      let(:relation_name) { 'stimuli' }
      let(:generate_cmd) { "hanami generate model #{model_name} --relation-name=#{relation_name}" }

      it 'creates correct migration' do
        with_project(project) do
          run_command generate_cmd

          migration = Pathname.new('db').join('migrations').children.find do |child|
            child.to_s.include?("create_#{relation_name}")
          end

          expect(migration.to_s).to have_file_content <<-END
Hanami::Model.migration do
  change do
    create_table :#{relation_name} do
      primary_key :id

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end
  end
end
END
        end
      end

      it 'set correct `relation` in repository' do
        with_project(project) do
          run_command generate_cmd

          expect("lib/#{project}/repositories/#{model_name}_repository.rb").to have_file_content <<-END
class #{class_name}Repository < Hanami::Repository
  self.relation = '#{relation_name}'
end
END
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

    it 'prints help message' do
      with_project do
        output = <<-OUT
Command:
  hanami generate model

Usage:
  hanami generate model MODEL

Description:
  Generate a model

Arguments:
  MODEL               	# REQUIRED Model name (eg. `user`)

Options:
  --[no-]skip-migration           	# Skip migration, default: false
  --relation-name=VALUE           	# Name of relation, default: pluralized model name
  --help, -h                      	# Print this help

Examples:
  hanami generate model user                          # Generate `User` entity, `UserRepository` repository, and the migration
  hanami generate model user --skip-migration         # Generate `User` entity and `UserRepository` repository
  hanami generate model user --relation-name=accounts # Generate `User` entity, `UserRepository` and migration to create `accounts` table
OUT

        run_command 'hanami generate model --help', output
      end
    end
  end # model
end
