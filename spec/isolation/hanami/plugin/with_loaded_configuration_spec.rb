RSpec.describe "Hanami.plugin" do
  it "configures plugin" do
    application = double("app")

    Hanami.configure{}
    Hanami.plugin do
      mount application, at: "/plugin"
    end

    app = Hanami.configuration.mounted.fetch(application)
    expect(app).to be_kind_of(Hanami::Configuration::App)
    expect(app.path_prefix).to eq("/plugin")
  end
end
