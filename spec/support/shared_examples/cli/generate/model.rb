require 'hanami/utils/string'

RSpec.shared_examples "a new model" do
  let(:model) { Hanami::Utils::String.new(input).underscore.to_s }

  it 'generates model' do
    class_name = Hanami::Utils::String.new(model).classify
    project    = "bookshelf_generate_model_#{Random.rand(100_000_000)}"

    with_project(project) do
      output = <<-OUT
      create  lib/#{project}/entities/#{model}.rb
      create  lib/#{project}/repositories/#{model}_repository.rb
      create  spec/#{project}/entities/#{model}_spec.rb
      create  spec/#{project}/repositories/#{model}_repository_spec.rb
OUT
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
      # spec/<project>/entities/<model>_spec.rb
      #
      expect("spec/#{project}/entities/#{model}_spec.rb").to have_file_content <<-END
require 'spec_helper'

describe #{class_name} do
  # place your tests here
end
END

      #
      # spec/<project>/repositories/<model>_repository_spec.rb
      #
      expect("spec/#{project}/repositories/#{model}_repository_spec.rb").to have_file_content <<-END
require 'spec_helper'

describe #{class_name}Repository do
  # place your tests here
end
END
    end
  end
end
