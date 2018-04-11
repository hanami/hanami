RSpec.describe "Hanami.code_reloading?", type: :integration do
  context "with shotgun" do
    it "returns true" do
      with_project do
        require Pathname.new(Dir.pwd).join("config", "environment")
        expect(Hanami.code_reloading?).to be(true)
      end
    end
  end
end
