RSpec.describe "Hanami.boot", type: :cli do
  it "boots project" do
    with_project do
      generate "app admin"

      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami.boot

      expect(Hanami::Components['apps.configurations']).to eq(true)
      expect(Hanami::Components['admin.configuration']).to be_kind_of(Hanami::ApplicationConfiguration)
      expect(Hanami::Components['web.configuration']).to   be_kind_of(Hanami::ApplicationConfiguration)
    end
  end
end
