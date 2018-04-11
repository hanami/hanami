RSpec.describe "Hanami.logger", type: :integration do
  it "returns logger instance" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "boot")
      expect(Hanami.logger).to be_kind_of(Hanami::Logger)
    end
  end
end
