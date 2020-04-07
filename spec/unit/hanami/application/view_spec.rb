require "hanami/application/view"

RSpec.describe Hanami::Application::View, :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
      end
    end
  end

  describe ".abstract_view?" do
    subject { view_class.abstract_view? }

    context "application view" do
      context "direct subclass" do
        let(:view_class) { Class.new(described_class) }
        it { is_expected.to be true }
      end

      context "further subclass" do
        let(:view_class) { Class.new(Class.new(described_class)) }
        it { is_expected.to be false }
      end
    end

    context "sliced view" do
      context "direct subclass" do
        let(:view_class) { Class.new(described_class::Sliced) }
        it { is_expected.to be true }
      end

      context "further subclass" do
        let(:view_class) { Class.new(Class.new(described_class::Sliced)) }
        it { is_expected.to be false }
      end
    end
  end
end
