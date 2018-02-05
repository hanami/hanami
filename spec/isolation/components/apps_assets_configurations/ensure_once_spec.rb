RSpec.describe "Components: apps.assets.configurations", type: :integration do
  it "ensures to load components once" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps.assets.configurations')

      assets            = Hanami::Components['apps.assets.configurations']
      web_configuration = Hanami::Components['web.configuration']
      web_app_config    = Web::Application.configuration

      # Simulate accidental double trigger
      Hanami::Components.resolve('apps.assets.configurations')

      expect(Hanami::Components['apps.assets.configurations']).to be(assets)
      expect(Hanami::Components['web.configuration']).to          be(web_configuration)
      expect(Web::Application.configuration).to                   be(web_app_config)
    end
  end
end
