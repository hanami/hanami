RSpec.describe "Components: app.routes", type: :cli do
  it "loads a single Hanami application's routes" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps') # the component under test can't be resolved directly

      # FIXME: this MUST be restored
      # expect(Hanami::Components['web.routes']).to be_kind_of(Hanami::Router)
      # expect(Web.routes).to                       be_kind_of(Hanami::Routes)
    end
  end
end
