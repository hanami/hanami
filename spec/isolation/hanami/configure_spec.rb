RSpec.describe "Hanami.configure" do
  before do
    application   = app
    model_config  = model_configuration
    mailer_config = mailer_configuration

    Hanami.configure do
      mount application, at: '/'
      model(&model_config)
      mailer(&mailer_config)
    end
  end

  let(:app) { double('app') }

  let(:model_configuration) do
    lambda do
      adapter :sql, uri: 'file://path/to/db.sqlite'

      migrations 'db/migrations'
      schema     'db/schema.sql'
    end
  end

  let(:mailer_configuration) do
    lambda do
      delivery :test
    end
  end

  it "setups apps" do
    mounted = Hanami.configuration.mounted
    expect(mounted[app]).to eq(Hanami::Configuration::App.new(app, '/'))
  end

  it "holds model configuration" do
    config = Hanami.configuration.model
    expect(config).to eq(model_configuration)
  end

  it "holds mailer configuration" do
    config = Hanami.configuration.mailer_settings
    expect(config).to eq([mailer_configuration])
  end
end
