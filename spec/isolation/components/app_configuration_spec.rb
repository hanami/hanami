RSpec.describe "Components: app.configuration", type: :integration do
  it "loads a single Hanami application's configuration within the project" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps') # the component under test can't be resolved directly

      configuration = Hanami::Components['web.configuration']

      expect(configuration).to be_kind_of(Hanami::ApplicationConfiguration)
      expect(configuration).to be(Web::Application.configuration)

      expect(configuration.namespace).to   be(Web)
      expect(configuration.path_prefix).to eq("/")
    end
  end
end
