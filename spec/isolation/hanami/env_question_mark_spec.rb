RSpec.describe "Hanami.env?", type: :integration do
  it "checks if the given env matches the current one" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")

      expect(Hanami.env?(:development)).to  be(true)
      expect(Hanami.env?('development')).to be(true)
      expect(Hanami.env?(:test)).to         be(false)

      expect(Hanami.env?(:development, :test)).to be(true)
      expect(Hanami.env?(:test, :production)).to  be(false)
    end
  end
end
