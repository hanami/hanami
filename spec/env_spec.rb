RSpec.describe Hanami::Env do
  after do
    ENV['HANAMI_ENV_TEST_VARIABLE'] = nil
  end

  describe "#[]" do
    it "reads value from ENV" do
      expect(described_class.new['PATH']).to eq(ENV['PATH'])
    end
  end

  describe "#[]=" do
    it "sets value to ENV" do
      subject = described_class.new
      subject['HANAMI_ENV_TEST_VARIABLE'] = 'foo'

      expect(subject['HANAMI_ENV_TEST_VARIABLE']).to eq(ENV['HANAMI_ENV_TEST_VARIABLE'])
    end
  end

  describe "#load!" do
    it "loads env vars" do
      env     = {}
      subject = described_class.new(env: env)

      subject.load!('spec/fixtures/dotenv/.env.development')
      expect(subject['BAZ']).to eq('yes')
    end
  end
end
