# frozen_string_literal: true

require "dry/system"
require "i18n"

RSpec.describe Hanami::Providers::I18n::Backend do
  let(:i18n_backend) { I18n::Backend::Simple.new }
  let(:backend) { described_class.new(i18n_backend, locale: :en, default_locale: :en, available_locales: []) }

  before do
    i18n_backend.store_translations(
      :en, {
        hello: "Hello",
        greeting: "Hello, %{name}!",
        messages: {
          welcome: "Welcome"
        }
      }
    )

    i18n_backend.store_translations(
      :fr, {
        hello: "Bonjour",
        greeting: "Bonjour, %{name}!",
        messages: {
          welcome: "Bienvenue"
        }
      }
    )
  end

  describe "#initialize" do
    it "sets the backend" do
      expect(backend.backend).to eq(i18n_backend)
    end

    it "sets default_locale" do
      expect(backend.default_locale).to eq(:en)
    end

    it "sets locale to default_locale by default" do
      expect(backend.locale).to eq(:en)
    end

    it "accepts custom locale" do
      custom_backend = described_class.new(i18n_backend, locale: :fr, default_locale: :en, available_locales: [])
      expect(custom_backend.locale).to eq(:fr)
    end

    it "accepts available_locales as array" do
      custom_backend = described_class.new(i18n_backend, locale: :en, default_locale: :en, available_locales: [:en, :fr])
      expect(custom_backend.instance_variable_get(:@available_locales)).to eq([:en, :fr])
    end

    it "converts available_locales to symbols" do
      custom_backend = described_class.new(i18n_backend, locale: :en, default_locale: :en, available_locales: ["en", "fr"])
      expect(custom_backend.instance_variable_get(:@available_locales)).to eq([:en, :fr])
    end

    it "handles empty available_locales" do
      custom_backend = described_class.new(i18n_backend, locale: :en, default_locale: :en, available_locales: [])
      expect(custom_backend.instance_variable_get(:@available_locales)).to eq([])
    end
  end

  describe "#t and #translate" do
    it "translates a simple key" do
      expect(backend.t(:hello)).to eq("Hello")
    end

    it "translates with interpolation" do
      expect(backend.t(:greeting, name: "World")).to eq("Hello, World!")
    end

    it "translates nested keys" do
      expect(backend.t("messages.welcome")).to eq("Welcome")
    end

    it "translates with explicit locale" do
      expect(backend.t(:hello, locale: :fr)).to eq("Bonjour")
    end

    it "uses current locale when set" do
      backend.locale = :fr
      expect(backend.t(:hello)).to eq("Bonjour")
    end

    it "returns the key as string when translation is missing and raise is false" do
      result = backend.t(:missing_key)
      expect(result).to eq("missing_key")
    end

    it "returns default when provided for missing translation" do
      expect(backend.t(:missing_key, default: "Fallback")).to eq("Fallback")
    end

    it "aliases #t to #translate" do
      expect(backend.t(:hello)).to eq(backend.translate(:hello))
    end
  end

  describe "#t!" do
    it "translates successfully" do
      expect(backend.t!(:hello)).to eq("Hello")
    end

    it "raises exception for missing translation" do
      expect { backend.t!(:missing_key) }.to raise_error(I18n::MissingTranslationData)
    end
  end

  describe "#localize and #l" do
    it "delegates to backend localize method" do
      time = Time.now
      allow(i18n_backend).to receive(:localize).with(:en, time, nil, {}).and_return("localized time")

      result = backend.localize(time)
      expect(result).to eq("localized time")
    end

    it "aliases #l to #localize" do
      time = Time.now
      allow(i18n_backend).to receive(:localize).and_return("localized")

      expect(backend.l(time)).to eq(backend.localize(time))
    end
  end

  describe "#exists?" do
    it "returns true for existing translation" do
      expect(backend.exists?(:hello)).to be true
    end

    it "returns false for missing translation" do
      expect(backend.exists?(:missing_key)).to be false
    end

    it "checks existence in specific locale" do
      expect(backend.exists?(:hello, locale: :fr)).to be true
      expect(backend.exists?(:missing, locale: :fr)).to be false
    end

    it "uses current locale" do
      backend.locale = :fr
      expect(backend.exists?(:hello)).to be true
    end
  end

  describe "#transliterate" do
    it "delegates to backend transliterate method" do
      allow(i18n_backend).to receive(:transliterate).with(:en, "Ærøskøbing", nil).and_return("AEroskobing")

      result = backend.transliterate("Ærøskøbing")
      expect(result).to eq("AEroskobing")
    end

    it "accepts locale parameter" do
      allow(i18n_backend).to receive(:transliterate).with(:fr, "test", nil).and_return("test")

      result = backend.transliterate("test", locale: :fr)
      expect(result).to eq("test")
    end
  end

  describe "#available_locales" do
    it "returns available locales from backend when not configured" do
      expect(backend.available_locales).to include(:en, :fr)
    end

    it "returns configured available_locales when set" do
      configured_backend = described_class.new(i18n_backend, locale: :en, default_locale: :en, available_locales: [:en, :fr])
      expect(configured_backend.available_locales).to contain_exactly(:en, :fr)
    end

    it "does not include locales outside configured available_locales" do
      i18n_backend.store_translations(:de, {hello: "Guten Tag"})

      configured_backend = described_class.new(i18n_backend, locale: :en, default_locale: :en, available_locales: [:en, :fr])
      expect(configured_backend.available_locales).to contain_exactly(:en, :fr)
      expect(configured_backend.available_locales).not_to include(:de)
    end

    it "returns all backend locales when available_locales is empty" do
      i18n_backend.store_translations(:de, {hello: "Guten Tag"})
      i18n_backend.store_translations(:es, {hello: "Hola"})

      expect(backend.available_locales).to include(:en, :fr, :de, :es)
    end
  end

  describe "#reload!" do
    it "delegates to backend reload!" do
      expect(i18n_backend).to receive(:reload!)
      backend.reload!
    end
  end

  describe "#eager_load!" do
    it "calls eager_load! on backend if supported" do
      allow(i18n_backend).to receive(:respond_to?).with(:eager_load!).and_return(true)
      expect(i18n_backend).to receive(:eager_load!)
      backend.eager_load!
    end

    it "does nothing if backend doesn't support eager_load!" do
      allow(i18n_backend).to receive(:respond_to?).with(:eager_load!).and_return(false)
      expect { backend.eager_load! }.not_to raise_error
    end
  end

  describe "#locale" do
    it "returns current locale from fiber-local storage" do
      backend.locale = :fr
      expect(backend.locale).to eq(:fr)
    end

    it "returns default_locale when locale storage is empty" do
      # Clear thread-local storage for this backend instance
      Thread.current[backend.instance_variable_get(:@storage_key)] = nil
      expect(backend.locale).to eq(:en)
    end
  end

  describe "#locale=" do
    it "sets the locale" do
      backend.locale = :fr
      expect(backend.locale).to eq(:fr)
    end

    it "converts string to symbol" do
      backend.locale = "de"
      expect(backend.locale).to eq(:de)
    end

    it "handles nil" do
      backend.locale = nil
      expect(backend.locale).to eq(:en) # Falls back to default_locale
    end
  end

  describe "#default_locale" do
    it "returns the default locale" do
      expect(backend.default_locale).to eq(:en)
    end
  end

  describe "#with_locale" do
    it "temporarily sets locale for the block" do
      backend.locale = :en
      expect(backend.locale).to eq(:en)

      backend.with_locale(:fr) do
        expect(backend.locale).to eq(:fr)
        expect(backend.t(:hello)).to eq("Bonjour")
      end

      expect(backend.locale).to eq(:en)
    end

    it "restores previous locale even if block raises" do
      backend.locale = :en

      expect {
        backend.with_locale(:fr) do
          raise "error"
        end
      }.to raise_error("error")

      expect(backend.locale).to eq(:en)
    end

    it "handles nested with_locale blocks" do
      backend.locale = :en

      backend.with_locale(:fr) do
        expect(backend.locale).to eq(:fr)

        backend.with_locale(:de) do
          expect(backend.locale).to eq(:de)
        end

        expect(backend.locale).to eq(:fr)
      end

      expect(backend.locale).to eq(:en)
    end

    it "handles nil locale" do
      backend.locale = :en

      backend.with_locale(nil) do
        expect(backend.locale).to eq(:en) # Falls back to default_locale
      end
    end
  end

  describe "thread safety" do
    it "maintains separate locales across threads" do
      backend.locale = :en

      threads = 2.times.map do |i|
        Thread.new do
          locale = i.zero? ? :fr : :de
          backend.locale = locale

          # Small delay to encourage race conditions if they exist
          sleep 0.01

          expect(backend.locale).to eq(locale)
        end
      end

      threads.each(&:join)
    end

    it "isolates with_locale across threads" do
      results = {}

      threads = [
        Thread.new do
          backend.with_locale(:fr) do
            sleep 0.01
            results[:thread1] = backend.t(:hello)
          end
        end,
        Thread.new do
          backend.with_locale(:en) do
            sleep 0.01
            results[:thread2] = backend.t(:hello)
          end
        end
      ]

      threads.each(&:join)

      expect(results[:thread1]).to eq("Bonjour")
      expect(results[:thread2]).to eq("Hello")
    end
  end

  describe "edge cases" do
    it "handles empty translation key" do
      expect { backend.t("") }.to raise_error(I18n::ArgumentError)
    end

    it "handles nil key with default option" do
      result = backend.t(nil, default: "fallback")
      expect(result).to eq("fallback")
    end

    it "handles scope option" do
      result = backend.t(:welcome, scope: :messages)
      expect(result).to eq("Welcome")
    end
  end

  describe "isolation between instances" do
    let(:other_backend_instance) { I18n::Backend::Simple.new }
    let(:other_backend) { described_class.new(other_backend_instance, locale: :de, default_locale: :de, available_locales: []) }

    before do
      other_backend_instance.store_translations(:de, {
                                                  hello: "Guten Tag"
                                                })
    end

    it "maintains separate backends" do
      expect(backend.t(:hello)).to eq("Hello")
      expect(other_backend.t(:hello)).to eq("Guten Tag")
    end

    it "maintains separate locale settings in the same thread" do
      # Each backend instance has its own thread-local storage key
      backend.locale = :en
      other_backend.locale = :de

      expect(backend.locale).to eq(:en)
      expect(other_backend.locale).to eq(:de)
    end

    it "doesn't share translations" do
      expect(backend.exists?(:hello, locale: :de)).to be false
      expect(other_backend.exists?(:hello, locale: :de)).to be true
    end

    it "maintains separate available_locales configuration" do
      backend_with_config = described_class.new(i18n_backend, locale: :en, default_locale: :en, available_locales: [:en])
      other_with_config = described_class.new(other_backend_instance, locale: :de, default_locale: :de, available_locales: [:de, :fr])

      expect(backend_with_config.available_locales).to contain_exactly(:en)
      expect(other_with_config.available_locales).to contain_exactly(:de, :fr)
    end
  end
end
