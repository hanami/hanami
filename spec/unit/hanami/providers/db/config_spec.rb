# frozen_string_literal: true

require "dry/system"
require "hanami/providers/db"

RSpec.describe "Hanami::Providers::DB.config", :app_integration do
  subject(:config) { provider.source.config }

  let(:provider) {
    Hanami.app.prepare
    Hanami.app.configure_provider(:db)
    Hanami.app.container.providers[:db]
  }

  before do
    module TestApp
      class App < Hanami::App
      end
    end
  end

  describe "#adapter" do
    it "adds an adapter" do
      expect { config.adapter(:yaml) }
        .to change { config.adapters.to_h }
        .to hash_including(:yaml)
    end

    it "yields the adapter for configuration" do
      expect { |b| config.adapter(:yaml, &b) }
        .to yield_with_args(an_instance_of(Hanami::Providers::DB::Adapter))
    end
  end

  describe "#any_adapter" do
    it "adds an adapter keyed without a name" do
      expect { config.any_adapter }
        .to change { config.adapters.to_h }
        .to hash_including(nil)
    end

    it "yields the adapter for configuration" do
      expect { |b| config.any_adapter(&b) }
        .to yield_with_args(an_instance_of(Hanami::Providers::DB::Adapter))
    end
  end

  describe "adapters" do
    subject(:adapter) { config.adapter(:yaml) }

    describe "#plugin" do
      it "adds a plugin without a block" do
        expect { adapter.plugin relations: :foo }
          .to change { adapter.plugins }
          .to [[{relations: :foo}, nil]]
      end

      it "adds a plugin with a block" do
        block = -> plugin_config { }

        expect {
          adapter.plugin(relations: :foo, &block)
        }
          .to change { adapter.plugins }
          .to [[{relations: :foo}, block]]
      end
    end

    describe "#plugins" do
      it "can be cleared" do
        adapter.plugin relations: :foo

        expect { adapter.plugins.clear }
          .to change { adapter.plugins }
          .to []
      end
    end

    describe "#gateway_cache_keys" do
      it "includes the configured extensions" do
        expect(adapter.gateway_cache_keys).to eq({})
      end
    end

    describe "#gateway_options" do
      specify do
        expect(adapter.gateway_options).to eq({})
      end
    end

    describe "#clear" do
      it "clears previously configured plugins" do
        adapter.plugin relations: :foo

        expect { adapter.clear }.to change { adapter.plugins }.to([])
      end
    end

    describe ":sql adapter" do
      subject(:adapter) { config.adapter(:sql) }

      describe "#extension" do
        it "adds an extension" do
          adapter.clear
          expect { adapter.extension :foo }
            .to change { adapter.extensions }
            .to [:foo]
        end

        it "adds multiple extensions" do
          adapter.clear
          expect { adapter.extension :foo, :bar }
            .to change { adapter.extensions }
            .to [:foo, :bar]
        end
      end

      describe "#extensions" do
        it "can be cleareed" do
          adapter.extension :foo

          expect { adapter.extensions.clear }
            .to change { adapter.extensions }
            .to []
        end
      end

      describe "#gateway_cache_keys" do
        it "includes the configured extensions" do
          adapter.clear
          adapter.extension :foo, :bar
          expect(adapter.gateway_cache_keys).to eq(extensions: [:foo, :bar])
        end
      end

      describe "#gateway_options" do
        it "includes the configured extensions" do
          adapter.clear
          adapter.extension :foo, :bar
          expect(adapter.gateway_options).to eq(extensions: [:foo, :bar])
        end
      end

      describe "#clear" do
        it "clears previously configured plugins and extensions" do
          adapter.plugin relations: :foo
          adapter.extension :foo

          expect { adapter.clear }
            .to change { adapter.plugins }.to([])
            .and change { adapter.extensions }.to([])
        end
      end
    end
  end
end
