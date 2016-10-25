RSpec.describe "Components: app.logger", type: :cli do
  it "loads a single Hanami application's hanami/logger configuration" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps') # the component under test can't be resolved directly

      expect(Web.logger).to be_kind_of(Hanami::Logger)
    end
  end
end
