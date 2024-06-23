# frozen_string_literal: true

require "dry/system"
require "hanami/providers/db"

RSpec.describe "Hanami::Providers::DB.config", :app_integration do
  subject(:config) { provider.source.config }

  let(:provider) {
    Hanami.app.configure_provider(:db)
    Hanami.app.container.providers[:db]
  }

  before do
    module TestApp
      class App < Hanami::App
      end
    end
  end

  describe "#adapter_name" do
    it "aliases #adapter" do
      expect { config.adapter = :yaml }
        .to change { config.adapter_name }
        .to :yaml
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
      it "clears previously configured plugins and extensions" do
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

      # TODO clear
    end
  end

  describe "#gateway_cache_keys" do
    it "returns the cache keys from the currently configured adapter" do
      config.adapter(:sql) { |a| a.clear; a.extension :foo }
      config.adapter = :sql

      expect(config.gateway_cache_keys).to eq(config.adapter(:sql).gateway_cache_keys)
    end
  end

  describe "#gateway_options" do
    it "returns the options from the currently configured adapter" do
      config.adapter(:sql) { |a| a.clear; a.extension :foo }
      config.adapter = :sql

      expect(config.gateway_options).to eq(config.adapter(:sql).gateway_options)
    end
  end

  describe "#each_plugin" do
    before do
      config.any_adapter { |a| a.plugin relations: :any_foo }
      config.adapter(:yaml) { |a| a.plugin relations: :yaml_foo }
      config.adapter = :yaml
    end

    it "yields the plugins specified for any adapter as well as the currently configured adapter" do
      expect { |b| config.each_plugin(&b) }
        .to yield_successive_args(
          [{relations: :any_foo}, nil],
          [{relations: :yaml_foo}, nil]
        )
    end

    it "returns the plugins as an enumerator if no block is given" do
      expect(config.each_plugin.to_a).to eq [
        [{relations: :any_foo}, nil],
        [{relations: :yaml_foo}, nil]
      ]
    end
  end
end
