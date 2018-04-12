RSpec.describe "Components: logger", type: :integration do
  let(:project_name) { "bookshelf" }

  it "setups Hanami project's logger" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('logger')

      expect(Hanami.logger).to be_kind_of(Hanami::Logger)
      expect(Hanami.logger.application_name).to eq(project_name)
      expect(Hanami.logger.level).to            eq(::Logger::DEBUG)
    end
  end
end
