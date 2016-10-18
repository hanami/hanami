RSpec.describe Hanami::Application do
  subject { UnitTesting::Application }

  describe ".app_name" do
    it "returns underscored name of the top level module" do
      expect(subject.app_name).to eq("unit_testing")
    end
  end

  describe ".configuration=" do
    before do
      subject.instance_variable_set(:@configuration, nil)
    end

    it "assigns configuration" do
      configuration = double("configuration")
      subject.configuration = configuration

      expect(subject.configuration).to eq(configuration)
    end

    it "raises error if assign configuration more than once" do
      configuration = double("configuration")
      subject.configuration = configuration

      expect { subject.configuration = configuration }.to raise_error(RuntimeError, "Can't assign configuration more than once (#{subject.app_name})")
    end
  end
end
