RSpec.describe "Components: app.code", type: :integration do
  it "loads a single Hanami application's code" do
    with_project do
      generate "action web home#index"

      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps') # the component under test can't be resolved directly

      expect(defined?(Web::Controllers::Home::Index)).to eq("constant")
      expect(defined?(Web::Views::Home::Index)).to       eq("constant")
    end
  end
end
