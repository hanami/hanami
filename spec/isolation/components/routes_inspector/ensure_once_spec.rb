RSpec.describe "Components: routes.inspector", type: :integration do
  it "ensures to load components once" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('routes.inspector')

      inspector     = Hanami::Components['routes.inspector']
      configuration = Hanami::Components['web.configuration']
      app_config    = Web::Application.configuration

      # Simulate accidental double trigger
      Hanami::Components.resolve('routes.inspector')

      expect(Hanami::Components['routes.inspector']).to  be(inspector)
      expect(Hanami::Components['web.configuration']).to be(configuration)
      expect(Web::Application.configuration).to          be(app_config)
    end
  end
end
