require 'hanami/utils/string'

RSpec.shared_examples "a new model" do
  let(:model) { Hanami::Utils::String.new(input).underscore.to_s }

  it 'generates model' do
    class_name = Hanami::Utils::String.new(model).classify
    table_name = Hanami::Utils::String.new(model).pluralize
    project    = "bookshelf_generate_model_#{Random.rand(100_000_000)}"

    with_project(project) do
      output = [
        "create  lib/#{project}/entities/#{model}.rb",
        "create  lib/#{project}/repositories/#{model}_repository.rb",
        /create  db\/migrations\/(\d+)_create_#{table_name}.rb/,
        "create  spec/#{project}/entities/#{model}_spec.rb",
        "create  spec/#{project}/repositories/#{model}_repository_spec.rb"
      ]

      run_command "hanami generate model #{input}", output

      #
      # lib/<project>/entities/<model>.rb
      #
      expect("lib/#{project}/entities/#{model}.rb").to have_file_content <<-END
class #{class_name} < Hanami::Entity
end
END

      #
      # lib/<project>/repositories/<model>_repository.rb
      #
      expect("lib/#{project}/repositories/#{model}_repository.rb").to have_file_content <<-END
class #{class_name}Repository < Hanami::Repository
end
END


      #
      # db/migrations/<timestamp>_create_<models>.rb
      #
      migrations = Pathname.new('db').join('migrations').children
      file       = migrations.find do |child|
        child.to_s.include?("create_#{table_name}")
      end
      expect(file).to_not be_nil, "Expected to find a migration matching: create_#{table_name}.\nFound: #{migrations.map(&:basename).join(' ')}"

      expect(file.to_s).to have_file_content <<-END
Hanami::Model.migration do
  change do
    create_table :#{table_name} do
      primary_key :id

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end
  end
end
END

      #
      # spec/<project>/entities/<model>_spec.rb
      #
      expect("spec/#{project}/entities/#{model}_spec.rb").to have_file_content <<-END
RSpec.describe #{class_name}, type: :entity do
  # place your tests here
end
END

      #
      # spec/<project>/repositories/<model>_repository_spec.rb
      #
      expect("spec/#{project}/repositories/#{model}_repository_spec.rb").to have_file_content <<-END
RSpec.describe #{class_name}Repository, type: :repository do
  # place your tests here
end
END
    end
  end
end
