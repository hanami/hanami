RSpec.describe "Components: app.assets", type: :integration do
  it "loads a single Hanami application's hanami-assets configuration" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps') # the component under test can't be resolved directly

      expect(Hanami::Components['web.assets']).to be_kind_of(Hanami::Assets::Configuration)
      expect(defined?(Web::Assets)).to            eq("constant")
    end
  end
end
