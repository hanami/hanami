RSpec.describe "Components: apps.assets.configurations", type: :integration do
  it "loads all assets configurations for each hanami applications in the project" do
    with_project do
      generate "app admin"

      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps.assets.configurations')

      expect(Hanami::Components['apps.configurations']).to_not be(nil)

      expect(Hanami::Components['apps.assets.configurations']).to be_any
      Hanami::Components['apps.assets.configurations'].each do |configuration|
        expect(configuration).to be_kind_of(Hanami::Assets::Configuration)
      end
    end
  end
end
