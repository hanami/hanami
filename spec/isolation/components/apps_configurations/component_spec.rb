RSpec.describe "Components: apps.configurations", type: :integration do
  it "loads all configurations for each hanami applications in the project" do
    with_project do
      generate "app admin"

      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps.configurations')

      expect(Hanami::Components['apps.configurations']).to be(true)

      expect(Hanami::Components['web.configuration']).to   be_kind_of(Hanami::ApplicationConfiguration)
      expect(Hanami::Components['admin.configuration']).to be_kind_of(Hanami::ApplicationConfiguration)
    end
  end
end
