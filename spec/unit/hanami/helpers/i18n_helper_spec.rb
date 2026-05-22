# frozen_string_literal: true

require "date"
require "dry/system"
require "i18n"

RSpec.describe Hanami::Helpers::I18nHelper do
  subject(:helper) {
    Class.new {
      include Hanami::View::Helpers::EscapeHelper
      include Hanami::Helpers::I18nHelper

      attr_reader :_context

      def initialize(context)
        @_context = context
      end
    }.new(context)
  }

  let(:context) { double(i18n:, current_template_name:) }
  let(:current_template_name) { nil }

  let(:i18n) do
    raw_backend = I18n::Backend::Simple.new
    raw_backend.load_translations(Hanami::Providers::I18n::BUNDLED_DEFAULTS_PATH)
    raw_backend.store_translations(
      :en, {
        hello: "Hello",
        greeting: "Hello, %{name}!",
        messages: {welcome: "Welcome"},
        greeting_html: "Hello, <strong>%{name}</strong>!",
        legal: {html: "<p>Read the <a href=\"/terms\">terms</a>.</p>"},
        users: {
          index: {
            title: "Users index",
            heading_html: "Hello, <strong>%{name}</strong>!",
            html: "<p>raw html</p>"
          },
          _form: {label: "Name"}
        },
        admin: {users: {index: {title: "Admin users index"}}},
        foo: {users: {index: {title: "Scoped title"}}},
        _form: {label: "Top-level form label"}
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

      it "escapes the key in the markup" do
        result = helper.translate("a<b>c")
        expect(result).to include "a&lt;b&gt;c"
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

      it "leaves already-html-safe interpolation values untouched" do
        safe_name = "<em>Alice</em>".html_safe
        result = helper.translate("greeting_html", name: safe_name)
        expect(result).to eq "Hello, <strong><em>Alice</em></strong>!"
      end

      it "does not raise on non-string interpolation values" do
        expect { helper.translate("greeting_html", name: 42) }.not_to raise_error
      end
    end

    context "non-HTML keys" do
      it "does not mark results as HTML-safe" do
        expect(helper.translate("hello")).not_to be_html_safe
      end

      it "does not pre-escape interpolation values" do
        expect(helper.translate("greeting", name: "<Alice>"))
          .to eq "Hello, <Alice>!"
      end
    end

    context "relative keys" do
      let(:current_template_name) { "users/index" }

      it "expands a leading-dot key against the current template name" do
        expect(helper.translate(".title")).to eq "Users index"
      end

      it "converts slashes in the template name to dots" do
        allow(context).to receive(:current_template_name).and_return("admin/users/index")
        expect(helper.translate(".title")).to eq "Admin users index"
      end

      it "expands symbol keys" do
        expect(helper.translate(:".title")).to eq "Users index"
      end

      it "preserves the leading underscore in partial basenames when expanding" do
        allow(context).to receive(:current_template_name).and_return("users/_form")
        expect(helper.translate(".label")).to eq "Name"
      end

      it "preserves the leading underscore for a top-level partial" do
        allow(context).to receive(:current_template_name).and_return("_form")
        expect(helper.translate(".label")).to eq "Top-level form label"
      end

      it "includes the expanded key in the missing-translation markup" do
        result = helper.translate(".nope")

        expect(result).to be_html_safe
        expect(result).to include "users.index.nope</span>"
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

      it "does not expand absolute keys even when a template is current" do
        expect(helper.translate("hello")).to eq "Hello"
      end

      it "does not treat array keys as relative" do
        # If arrays were treated as relative, calling translate with no template current
        # would raise I18n::ArgumentError. Confirm it doesn't.
        allow(context).to receive(:current_template_name).and_return(nil)
        expect { helper.translate([".missing", :hello]) }.not_to raise_error
      end

      it "composes with the :scope option" do
        expect(helper.translate(".title", scope: :foo)).to eq "Scoped title"
      end

      context "when no template is being rendered" do
        let(:current_template_name) { nil }

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

    it "marks `_html` results as HTML-safe and escapes interpolations" do
      result = helper.translate!("greeting_html", name: "<script>")
      expect(result).to be_html_safe
      expect(result).to eq "Hello, <strong>&lt;script&gt;</strong>!"
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

    it "respects an explicit :locale" do
      expect(helper.localize(Date.new(2026, 5, 11), format: :short, locale: :en))
        .to eq "11 May"
    end
  end
end
