RSpec.describe "Components: logger", type: :integration do
  it "allows custom loggers" do
    with_project do
      replace 'config/environment.rb', 'logger ', "logger ::Logger.new(STDOUT)"

      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('logger')

      expect(Hanami.logger.class).to eq(::Logger)
    end
  end

  it "allows loggers not based on ::Logger" do
    with_project do
      replace 'config/environment.rb', 'logger ', "logger SemanticLogger.new"

      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('logger')

      expect(Hanami.logger.class).to eq(SemanticLogger)
    end
  end
end
