RSpec.describe "Components: apps.configurations", type: :integration do
  it "ensures to load components once" do
    with_project do
      generate "app admin"

      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps.configurations')

      web_configuration   = Hanami::Components['web.configuration']
      admin_configuration = Hanami::Components['admin.configuration']
      web_app_config      = Web::Application.configuration
      admin_app_config    = Admin::Application.configuration

      # Simulate accidental double trigger
      Hanami::Components.resolve('apps.configurations')

      expect(Hanami::Components['web.configuration']).to   be(web_configuration)
      expect(Hanami::Components['admin.configuration']).to be(admin_configuration)
      expect(Web::Application.configuration).to            be(web_app_config)
      expect(Admin::Application.configuration).to          be(admin_app_config)
    end
  end
end
