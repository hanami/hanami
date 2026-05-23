# frozen_string_literal: true

require "date"
require "dry/system"
require "i18n"

RSpec.describe Hanami::Extensions::Action::I18nHelper do
  subject(:helper) {
    klass = Class.new {
      include Hanami::Extensions::Action::I18nHelper

      attr_reader :i18n

      def initialize(i18n)
        @i18n = i18n
      end
    }

    config = Struct.new(:i18n_key_base).new(i18n_key_base)
    klass.define_singleton_method(:config) { config }

    klass.new(i18n_backend)
  }

  let(:i18n_key_base) { nil }

  let(:i18n_backend) do
    raw_backend = I18n::Backend::Simple.new
    raw_backend.load_translations(Hanami::Providers::I18n::BUNDLED_DEFAULTS_PATH)
    raw_backend.store_translations(
      :en, {
        hello: "Hello",
        greeting: "Hello, %{name}!",
        messages: {welcome: "Welcome"},
        greeting_html: "Hello, <strong>%{name}</strong>!",
        legal: {html: "<p>Read the <a href=\"/terms\">terms</a>.</p>"},
        posts: {
          show: {
            title: "Post title",
            heading_html: "Hello, <strong>%{name}</strong>!",
            html: "<p>raw html</p>"
          }
        },
        foo: {posts: {show: {title: "Scoped title"}}}
      }
    )

    Hanami::Providers::I18n::Backend.new(
      raw_backend,
      default_locale: :en,
      available_locales: [:en]
    )
  end

  describe "#translate" do
    it "translates the given key" do
      expect(helper.translate("hello")).to eq "Hello"
    end

    it "interpolates string options" do
      expect(helper.translate("greeting", name: "Alice")).to eq "Hello, Alice!"
    end

    it "is aliased as #t" do
      expect(helper.t("hello")).to eq "Hello"
    end

    it "respects an explicit :locale" do
      expect(helper.translate("hello", locale: :en)).to eq "Hello"
    end

    it "respects an explicit :default for missing translations" do
      expect(helper.translate("missing.key", default: "Fallback")).to eq "Fallback"
    end

    it "raises when given raise: true and the translation is missing" do
      expect { helper.translate("missing.key", raise: true) }
        .to raise_error(I18n::MissingTranslationData)
    end

    context "missing translation" do
      it "returns a translation_missing span" do
        result = helper.translate("missing.key")

        expect(result).to be_html_safe
        expect(result).to include 'class="translation_missing"'
        expect(result).to include "missing.key</span>"
      end
    end

    context "HTML-safe keys" do
      it "marks results from `_html`-suffixed keys as HTML-safe" do
        result = helper.translate("greeting_html", name: "Alice")
        expect(result).to be_html_safe
        expect(result).to eq "Hello, <strong>Alice</strong>!"
      end

      it "marks results from keys whose final segment is `html` as HTML-safe" do
        result = helper.translate("legal.html")
        expect(result).to be_html_safe
        expect(result).to include "<p>Read the"
      end

      it "escapes interpolated string values to prevent injection" do
        result = helper.translate("greeting_html", name: "<script>alert(1)</script>")
        expect(result).to be_html_safe
        expect(result).to eq "Hello, <strong>&lt;script&gt;alert(1)&lt;/script&gt;</strong>!"
      end
    end

    context "non-HTML keys" do
      it "does not mark results as HTML-safe" do
        expect(helper.translate("hello")).not_to be_html_safe
      end
    end

    context "relative keys" do
      let(:i18n_key_base) { "posts.show" }

      it "expands a leading-dot key against the action's i18n_key_base" do
        expect(helper.translate(".title")).to eq "Post title"
      end

      it "expands symbol keys" do
        expect(helper.translate(:".title")).to eq "Post title"
      end

      it "includes the expanded key in the missing-translation markup" do
        result = helper.translate(".nope")

        expect(result).to be_html_safe
        expect(result).to include "posts.show.nope</span>"
      end

      it "preserves HTML safety for expanded `_html` keys and escapes interpolations" do
        result = helper.translate(".heading_html", name: "<script>")

        expect(result).to be_html_safe
        expect(result).to eq "Hello, <strong>&lt;script&gt;</strong>!"
      end

      it "preserves HTML safety for expanded `.html` keys" do
        result = helper.translate(".html")

        expect(result).to be_html_safe
        expect(result).to eq "<p>raw html</p>"
      end

      it "does not expand absolute keys even when an i18n_key_base is set" do
        expect(helper.translate("hello")).to eq "Hello"
      end

      it "composes with the :scope option" do
        expect(helper.translate(".title", scope: :foo)).to eq "Scoped title"
      end

      context "without an i18n_key_base" do
        let(:i18n_key_base) { nil }

        it "raises I18n::ArgumentError from #translate" do
          expect { helper.translate(".title") }
            .to raise_error(I18n::ArgumentError, /relative translation key/)
        end

        it "raises I18n::ArgumentError from #translate!" do
          expect { helper.translate!(".title") }
            .to raise_error(I18n::ArgumentError, /relative translation key/)
        end
      end
    end
  end

  describe "#translate!" do
    it "translates the given key" do
      expect(helper.translate!("hello")).to eq "Hello"
    end

    it "raises for missing translations" do
      expect { helper.translate!("missing.key") }
        .to raise_error I18n::MissingTranslationData
    end

    it "is aliased as #t!" do
      expect { helper.t!("missing.key") }
        .to raise_error I18n::MissingTranslationData
    end
  end

  describe "#localize" do
    it "localizes the given object with a symbol format" do
      expect(helper.localize(Date.new(2026, 5, 11), format: :short)).to eq "11 May"
    end

    it "localizes with a locale-dependent strftime format string" do
      expect(helper.localize(Date.new(2026, 5, 11), format: "%B %d")).to eq "May 11"
    end

    it "is aliased as #l" do
      expect(helper.l(Date.new(2026, 5, 11), format: :short)).to eq "11 May"
    end
  end
end
