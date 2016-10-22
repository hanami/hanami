RSpec.describe "Components: all", type: :cli do
  it "ensures to load components once" do
    with_project do
      generate "app admin"

      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('all')

      model_configuration = Hanami::Components['model.configuration']
      model               = Hanami::Components['model']
      web_configuration   = Hanami::Components['web.configuration']
      web_app_config      = Web::Application.configuration
      admin_configuration = Hanami::Components['admin.configuration']
      admin_app_config    = Admin::Application.configuration

      # Simulate accidental double trigger
      Hanami::Components.resolve('all')

      expect(Hanami::Components['model.configuration']).to be(model_configuration)
      expect(Hanami::Components['model']).to               be(model)
      expect(Hanami::Components['web.configuration']).to   be(web_configuration)
      expect(Web::Application.configuration).to            be(web_app_config)
      expect(Hanami::Components['admin.configuration']).to be(admin_configuration)
      expect(Admin::Application.configuration).to          be(admin_app_config)
    end
  end
end
