RSpec.describe "Components: apps", type: :integration do
  it "loads all project hanami applications" do
    with_project do
      generate "app admin"

      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps')

      expect(Hanami::Components['web']).to_not   be(nil)
      expect(Hanami::Components['admin']).to_not be(nil)
    end
  end
end
