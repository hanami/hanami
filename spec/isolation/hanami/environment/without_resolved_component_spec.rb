RSpec.describe "Hanami.environment", type: :integration do
  context "without resolved component" do
    it "returns Hanami::Environment" do
      with_project do
        require Pathname.new(Dir.pwd).join("config", "environment")
        expect(Hanami.environment).to be_kind_of(Hanami::Environment)
      end
    end
  end
end
