RSpec.describe "Components: app.controller", type: :cli do
  it "resolves controller configuration for app" do
    with_project do
      generate "app admin"

      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps')

      expect(Hanami::Components['web.controller']).to   be_kind_of(Hanami::Controller::Configuration)
      expect(Hanami::Components['admin.controller']).to be_kind_of(Hanami::Controller::Configuration)

      expect(Hanami::Components['web.controller']).to_not eq(Hanami::Components['admin.controller'])
    end
  end
end
