RSpec.describe "Hanami.environment", type: :integration do
  context "with resolved component" do
    it "returns Hanami::Environment" do
      with_project do
        require Pathname.new(Dir.pwd).join("config", "environment")
        Hanami::Components.resolved('environment', Hanami::Environment.new(code_reloading: false))

        expect(Hanami.environment).to                 be_kind_of(Hanami::Environment)
        expect(Hanami.environment.code_reloading?).to be(false)
      end
    end
  end
end
