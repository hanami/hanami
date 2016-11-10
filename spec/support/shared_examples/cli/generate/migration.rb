require 'hanami/utils/string'

RSpec.shared_examples "a new migration" do
  let(:migration) { Hanami::Utils::String.new(input).underscore.to_s }

  it 'generates migration' do
    project = "bookshelf_generate_migration_#{Random.rand(100_000_000)}"

    with_project(project) do
      run_command "hanami generate migration #{input}", migration

      #
      # db/migrations/<timestamp>_<migration>.rb
      #
      migrations = Pathname.new('db').join('migrations').children
      file       = migrations.find do |child|
        child.to_s.include?(migration)
      end

      expect(file).to_not be_nil, "Expected to find a migration matching: #{file}.\nFound: #{migrations.map(&:basename).join(' ')}"

      expect(file.to_s).to have_file_content <<-END
Hanami::Model.migration do
  change do
  end
end
END
    end
  end
end
