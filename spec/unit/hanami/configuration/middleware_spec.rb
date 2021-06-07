# frozen_string_literal: true

require "hanami/configuration"

RSpec.describe Hanami::Configuration do
  subject(:config) { described_class.new(env: :development) }

  describe "#middleware" do
    it "defaults to a stack with no configured middlewares" do
      expect(config.middleware).to be_kind_of(Hanami::Configuration::Middleware)
      expect(config.middleware.stack.count).to be(0)
    end

    describe "#use" do
      it "adds a middleware object to the configured stack" do
        middleware = -> * {}

        expect { config.middleware.use middleware }
          .to change { config.middleware.stack }
          .to [[middleware]]
      end

      it "adds a middleware class with options and a block to the configured stack" do
        klass, opts, block = Class.new, {options: :here}, -> * {}

        expect { config.middleware.use(klass, opts, &block) }
          .to change { config.middleware.stack }
          .to [[klass, opts, block]]
      end
    end
  end

  describe "#for_each_middleware" do
    let(:middleware_item_1) { [Class.new, {options: :here}, -> * {}] }
    let(:middleware_item_2) { [Class.new, {options: :here}, -> * {}] }

    before do
      config.middleware.use(*middleware_item_1)
      config.middleware.use(*middleware_item_2)
    end

    context "sessions not enabled" do
      it "yields each given middleware" do
        expect { |b| config.for_each_middleware(&b) }
          .to yield_successive_args middleware_item_1, middleware_item_2
      end
    end

    context "sessions enabled" do
      before do
        config.sessions = :cookie, {secret: "xyz"}
      end

      it "yields each given middleware, with the session middleware added last" do
        expect { |b| config.for_each_middleware(&b) }
          .to yield_successive_args(
            middleware_item_1,
            middleware_item_2,
            array_including(an_object_satisfying { |klass| klass.name =~ /^Rack::Session/ })
          )
      end
    end
  end
end
