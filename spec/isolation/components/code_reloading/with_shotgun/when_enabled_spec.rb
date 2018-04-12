RSpec.describe "Components: code_reloading", type: :integration do
  context "with shotgun" do
    context "with code reloading enabled" do
      it "is true" do
        with_project do
          require Pathname.new(Dir.pwd).join("config", "environment")
          Hanami::Components.resolved('environment', Hanami::Environment.new(code_reloading: true))
          Hanami::Components.resolve('code_reloading')

          expect(Hanami::Components['code_reloading']).to be(true)
        end
      end
    end
  end
end
