# frozen_string_literal: true

require "hanami/helpers/form_helper"
require "hanami/view/erb/template"

RSpec.describe Hanami::Helpers::FormHelper do
  subject(:obj) {
    Class.new {
      include Hanami::Helpers::FormHelper

      attr_reader :_context

      def initialize(context)
        @_context = context
      end
    }.new(context)
  }

  let(:context) {
    Hanami::View::Context.new(request: request, inflector: Dry::Inflector.new)
  }

  let(:request) {
    Hanami::Action::Request.new(env: rack_request, params: params, session_enabled: true)
  }

  let(:rack_request) {
    Rack::MockRequest.env_for("http://example.com/")
  }

  let(:params) { {} }

  def form_for(...)
    obj.instance_eval { form_for(...) }
  end

  def h(&block)
    obj.instance_eval(&block)
  end

  def render(erb)
    Hanami::View::ERB::Template.new { erb }.render(obj)
  end

  describe "#form_for" do
    it "renders" do
      html = form_for("/books")
      expect(html).to eq %(<form action="/books" accept-charset="utf-8" method="POST"></form>)
    end

    it "allows to assign 'id' attribute" do
      html = form_for("/books", id: "book-form")

      expect(html).to eq %(<form action="/books" id="book-form" accept-charset="utf-8" method="POST"></form>)
    end

    it "allows to override 'method' attribute ('get')" do
      html = form_for("/books", method: "get")
      expect(html).to eq %(<form action="/books" method="GET" accept-charset="utf-8"></form>)
    end

    it "allows to override 'method' attribute (:get)" do
      html = form_for("/books", method: :get)
      expect(html).to eq %(<form action="/books" method="GET" accept-charset="utf-8"></form>)
    end

    it "allows to override 'method' attribute ('GET')" do
      html = form_for("/books", method: "GET")
      expect(html).to eq %(<form action="/books" method="GET" accept-charset="utf-8"></form>)
    end

    %i[patch put delete].each do |verb|
      it "allows to override 'method' attribute (#{verb})" do
        html = form_for("/books", method: verb) do |f|
          f.text_field "book.title"
        end

        expect(html).to eq %(<form action="/books" method="POST" accept-charset="utf-8"><input type="hidden" name="_method" value="#{verb.to_s.upcase}"><input type="text" name="book[title]" id="book-title" value=""></form>)
      end
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books", class: "form-horizonal")
      expect(html).to eq %(<form action="/books" class="form-horizonal" accept-charset="utf-8" method="POST"></form>)
    end

    context "input name" do
      it "sets a base name" do
        expected_html = <<~HTML
          <form action="/books" accept-charset="utf-8" method="POST">
            <input type="text" name="book[author][avatar][url]" id="book-author-avatar-url" value="">
          </form>
        HTML

        html = form_for("book", "/books") do |f|
          f.text_field("author.avatar.url")
        end

        expect(html).to eq_html expected_html

        html = form_for("book", "/books") do |f|
          f.fields_for("author.avatar") do |fa|
            fa.text_field("url")
          end
        end

        expect(html).to eq_html expected_html
      end

      it "renders nested field names" do
        html = form_for("/books") do |f|
          f.text_field "book.author.avatar.url"
        end

        expect(html).to include %(<input type="text" name="book[author][avatar][url]" id="book-author-avatar-url" value="">)
      end

      context "using values from scope locals" do
        let(:values) { {book: double("book", author: double("author", avatar: double("avatar", url: val)))} }
        let(:val) { "https://hanami.test/avatar.png" }

        before do
          # TODO: Maybe our `obj` should actually be a real Scope subclass
          values = self.values
          obj.define_singleton_method(:_locals) { values }
        end

        it "renders with value" do
          html = form_for("/books") do |f|
            f.text_field "book.author.avatar.url"
          end

          expect(html).to include %(<input type="text" name="book[author][avatar][url]" id="book-author-avatar-url" value="#{val}">)
        end
      end

      context "with explicit values given" do
        let(:values) { {book: double("book", author: double("author", avatar: double("avatar", url: val)))} }
        let(:val) { "https://hanami.test/avatar.png" }

        it "renders with value" do
          html = form_for("/books", values: values) do |f|
            f.text_field "book.author.avatar.url"
          end

          expect(html).to include %(<input type="text" name="book[author][avatar][url]" id="book-author-avatar-url" value="#{val}">)
        end

        it "allows to override 'value' attribute" do
          html = form_for("/books", values: values) do |f|
            f.text_field "book.author.avatar.url", value: "https://hanami.test/another-avatar.jpg"
          end

          expect(html).to include %(<input type="text" name="book[author][avatar][url]" id="book-author-avatar-url" value="https://hanami.test/another-avatar.jpg">)
        end
      end

      context "with filled params" do
        let(:params) { {book: {author: {avatar: {url: val}}}} }
        let(:val) { "https://hanami.test/avatar.png" }

        it "renders with value" do
          html = form_for("/books") do |f|
            f.text_field "book.author.avatar.url"
          end

          expect(html).to include %(<input type="text" name="book[author][avatar][url]" id="book-author-avatar-url" value="#{val}">)
        end

        it "allows to override 'value' attribute" do
          html = form_for("/books") do |f|
            f.text_field "book.author.avatar.url", value: "https://hanami.test/another-avatar.jpg"
          end

          expect(html).to include %(<input type="text" name="book[author][avatar][url]" id="book-author-avatar-url" value="https://hanami.test/another-avatar.jpg">)
        end
      end
    end

    context "CSRF protection" do
      let(:csrf_token) { "abc123" }

      before do
        allow(request).to receive(:session) { {_csrf_token: csrf_token} }
      end

      it "injects hidden field session is enabled" do
        html = form_for("/books")
        expect(html).to eq %(<form action="/books" accept-charset="utf-8" method="POST"><input type="hidden" name="_csrf_token" value="#{csrf_token}"></form>)
      end

      context "with missing token" do
        let(:csrf_token) { nil }

        it "doesn't inject hidden field" do
          html = form_for("/books")
          expect(html).to eq %(<form action="/books" accept-charset="utf-8" method="POST"></form>)
        end
      end

      context "with csrf_token on get verb" do
        it "doesn't inject hidden field" do
          html = form_for("/books", method: "GET")
          expect(html).to eq %(<form action="/books" method="GET" accept-charset="utf-8"></form>)
        end
      end

      %i[patch put delete].each do |verb|
        it "it injects hidden field when method override (#{verb}) is active" do
          html = form_for("/books", method: verb)
          expect(html).to eq %(<form action="/books" method="POST" accept-charset="utf-8"><input type="hidden" name="_method" value="#{verb.to_s.upcase}"><input type="hidden" name="_csrf_token" value="#{csrf_token}"></form>)
        end
      end
    end

    context "CSRF meta tags" do
      let(:csrf_token) { "abc123" }

      before do
        allow(request).to receive(:session) { {_csrf_token: csrf_token} }
      end

      def csrf_meta_tags(...)
        h { csrf_meta_tags(...) }
      end

      it "prints meta tags" do
        html = csrf_meta_tags
        expect(html).to eq %(<meta name="csrf-param" content="_csrf_token"><meta name="csrf-token" content="#{csrf_token}">)
      end

      context "when CSRF token is nil" do
        let(:csrf_token) { nil }

        it "returns nil" do
          expect(csrf_meta_tags).to be(nil)
        end
      end
    end

    context "remote: true" do
      it "adds data-remote=true to form attributes" do
        html = form_for("/books", "data-remote": true)
        expect(html).to eq %(<form action="/books" data-remote="true" accept-charset="utf-8" method="POST"></form>)
      end

      it "adds data-remote=false to form attributes" do
        html = form_for("/books", "data-remote": false)
        expect(html).to eq %(<form action="/books" data-remote="false" accept-charset="utf-8" method="POST"></form>)
      end

      it "adds data-remote= to form attributes" do
        html = form_for("/books", "data-remote": nil)
        expect(html).to eq %(<form action="/books" accept-charset="utf-8" method="POST"></form>)
      end
    end

    context "explicitly given params" do
      let(:params) { {song: {title: "Orphans"}} }
      let(:given_params) { {song: {title: "Arabesque"}} }
      let(:action) { "/songs" }

      it "renders" do
        html = form_for("/songs", params: given_params) do |f|
          f.text_field "song.title"
        end

        expect(html).to eq(%(<form action="/songs" accept-charset="utf-8" method="POST"><input type="text" name="song[title]" id="song-title" value="Arabesque"></form>))
      end
    end
  end

  describe "#fields_for" do
    it "renders" do
      html = render(<<~ERB)
        <%= form_for("/books") do |f| %>
          <% f.fields_for "book.categories" do |fa| %>
            <%= fa.text_field :name %>

            <% fa.fields_for :subcategories do |fb| %>
              <%= fb.text_field :name %>
            <% end %>

            <%= fa.text_field :name2 %>
          <% end %>

          <%= f.text_field "book.title" %>
        <% end %>
      ERB

      expect(html).to eq_html <<~HTML
        <form action="/books" accept-charset="utf-8" method="POST">
          <input type="text" name="book[categories][name]" id="book-categories-name" value="">
          <input type="text" name="book[categories][subcategories][name]" id="book-categories-subcategories-name" value="">
          <input type="text" name="book[categories][name2]" id="book-categories-name2" value="">
          <input type="text" name="book[title]" id="book-title" value="">
        </form>
      HTML
    end

    describe "with filled params" do
      let(:params) { {book: {title: "TDD", categories: {name: "foo", name2: "bar", subcategories: {name: "sub"}}}} }

      it "renders" do
        html = render(<<~ERB)
          <%= form_for("/books") do |f| %>
            <% f.fields_for "book.categories" do |fa| %>
              <%= fa.text_field :name %>

              <% fa.fields_for :subcategories do |fb| %>
                <%= fb.text_field :name %>
              <% end %>

              <%= fa.text_field :name2 %>
            <% end %>

            <%= f.text_field "book.title" %>
          <% end %>
        ERB

        expect(html).to eq_html <<~HTML
          <form action="/books" accept-charset="utf-8" method="POST">
            <input type="text" name="book[categories][name]" id="book-categories-name" value="foo">
            <input type="text" name="book[categories][subcategories][name]" id="book-categories-subcategories-name" value="sub">
            <input type="text" name="book[categories][name2]" id="book-categories-name2" value="bar">
            <input type="text" name="book[title]" id="book-title" value="TDD">
          </form>
        HTML
      end
    end
  end

  describe "#fields_for_collection" do
    let(:params) { {book: {categories: [{name: "foo", new: true, genre: nil}]}} }

    it "renders" do
      html = render(<<~ERB)
        <%= form_for("/books") do |f| %>
          <% f.fields_for_collection "book.categories" do |fa| %>
            <%= fa.text_field :name %>
            <%= fa.hidden_field :name %>
            <%= fa.text_area :name %>
            <%= fa.check_box :new %>
            <%= fa.select :genre, [%w[Terror terror], %w[Comedy comedy]] %>
            <%= fa.color_field :name %>
            <%= fa.date_field :name %>
            <%= fa.datetime_field :name %>
            <%= fa.datetime_local_field :name %>
            <%= fa.time_field :name %>
            <%= fa.month_field :name %>
            <%= fa.week_field :name %>
            <%= fa.email_field :name %>
            <%= fa.url_field :name %>
            <%= fa.tel_field :name %>
            <%= fa.file_field :name %>
            <%= fa.number_field :name %>
            <%= fa.range_field :name %>
            <%= fa.search_field :name %>
            <%= fa.radio_button :name, "Fiction" %>
            <%= fa.password_field :name %>
            <%= fa.datalist :name, ["Italy", "United States"], "books" %>
          <% end %>
        <% end %>
      ERB

      expected = <<~HTML
        <form action="/books" enctype="multipart/form-data" accept-charset="utf-8" method="POST">
          <input type="text" name="book[categories][][name]" id="book-categories-0-name" value="foo">
          <input type="hidden" name="book[categories][][name]" id="book-categories-0-name" value="foo">
          <textarea name="book[categories][][name]" id="book-categories-0-name">
          foo</textarea>
          <input type="hidden" name="book[categories][][new]" value="0"><input type="checkbox" name="book[categories][][new]" id="book-categories-0-new" value="1" checked="checked">
          <select name="book[categories][][genre]" id="book-categories-0-genre"><option value="terror">Terror</option><option value="comedy">Comedy</option></select>
          <input type="color" name="book[categories][][name]" id="book-categories-0-name" value="foo">
          <input type="date" name="book[categories][][name]" id="book-categories-0-name" value="foo">
          <input type="datetime" name="book[categories][][name]" id="book-categories-0-name" value="foo">
          <input type="datetime-local" name="book[categories][][name]" id="book-categories-0-name" value="foo">
          <input type="time" name="book[categories][][name]" id="book-categories-0-name" value="foo">
          <input type="month" name="book[categories][][name]" id="book-categories-0-name" value="foo">
          <input type="week" name="book[categories][][name]" id="book-categories-0-name" value="foo">
          <input type="email" name="book[categories][][name]" id="book-categories-0-name" value="foo">
          <input type="url" name="book[categories][][name]" id="book-categories-0-name" value="">
          <input type="tel" name="book[categories][][name]" id="book-categories-0-name" value="foo">
          <input type="file" name="book[categories][][name]" id="book-categories-0-name">
          <input type="number" name="book[categories][][name]" id="book-categories-0-name" value="foo">
          <input type="range" name="book[categories][][name]" id="book-categories-0-name" value="foo">
          <input type="search" name="book[categories][][name]" id="book-categories-0-name" value="foo">
          <input type="radio" name="book[categories][][name]" value="Fiction">
          <input type="password" name="book[categories][][name]" id="book-categories-0-name" value="">
          <input type="text" name="book[categories][][name]" id="book-categories-0-name" value="foo" list="books"><datalist id="books"><option value="Italy"></option><option value="United States"></option></datalist>
        </form>
      HTML

      expect(html).to eq_html(expected)
    end
  end

  describe "#label" do
    it "renders capitalized string" do
      html = form_for("/books") do |f|
        f.label "book.free_shipping"
      end

      expect(html).to include %(<label for="book-free-shipping">Free shipping</label>)
    end

    it "accepts a string as custom content" do
      html = form_for("/books") do |f|
        f.label "Free Shipping!", for: "book.free_shipping"
      end

      expect(html).to include %(<label for="book-free-shipping">Free Shipping!</label>)
    end

    it "renders a label with block" do
      html = render(<<~ERB)
        <%= form_for "/books" do |f| %>
          <%= f.label for: "book.free_shipping" do %>
            Free Shipping
            <%= tag.abbr "*", title: "optional", aria: {label: "optional"} %>
          <% end %>
        <% end %>
      ERB

      expect(html).to eq <<~HTML
        <form action="/books" accept-charset="utf-8" method="POST">
          <label for="book-free-shipping">
            Free Shipping
            <abbr title="optional" aria-label="optional">*</abbr>
          </label>
        </form>
      HTML
    end
  end

  describe "#button" do
    it "renders a button" do
      html = form_for("/books") do |f|
        f.button "Click me"
      end

      expect(html).to include %(<button>Click me</button>)
    end

    it "renders a button with HTML attributes" do
      html = form_for("/books") do |f|
        f.button "Click me", class: "btn btn-secondary"
      end

      expect(html).to include(%(<button class="btn btn-secondary">Click me</button>))
    end

    it "renders a button with block" do
      html = render(<<~ERB)
        <%= form_for("/books") do |f| %>
          <%= f.button class: "btn btn-secondary" do %>
            <%= tag.span class: "oi oi-check" %>
          <% end %>
        <% end %>
      ERB

      expect(html).to eq <<~HTML
        <form action="/books" accept-charset="utf-8" method="POST">
          <button class="btn btn-secondary">
            <span class="oi oi-check"></span>
          </button>
        </form>
      HTML
    end
  end

  describe "#submit" do
    it "renders a submit button" do
      html = form_for("/books") do |f|
        f.submit "Create"
      end

      expect(html).to include %(<button type="submit">Create</button>)
    end

    it "renders a submit button with HTML attributes" do
      html = form_for("/books") do |f|
        f.submit "Create", class: "btn btn-primary"
      end

      expect(html).to include %(<button type="submit" class="btn btn-primary">Create</button>)
    end

    it "renders a submit button with block" do
      html = render(<<~ERB)
        <%= form_for "/books" do |f| %>
          <%= f.submit class: "btn btn-primary" do %>
            <%= tag.span class: "oi oi-check" %>
          <% end %>
        <% end %>
      ERB

      expect(html).to eq <<~HTML
        <form action="/books" accept-charset="utf-8" method="POST">
          <button type="submit" class="btn btn-primary">
            <span class="oi oi-check"></span>
          </button>
        </form>
      HTML
    end
  end

  describe "#image_button" do
    it "renders an image button" do
      html = form_for("/books") do |f|
        f.image_button "https://hanamirb.org/assets/image_button.png"
      end

      expect(html).to include %(<input type="image" src="https://hanamirb.org/assets/image_button.png">)
    end

    it "renders an image button with HTML attributes" do
      html = form_for("/books") do |f|
        f.image_button "https://hanamirb.org/assets/image_button.png", name: "image", width: "50"
      end

      expect(html).to include %(<input name="image" width="50" type="image" src="https://hanamirb.org/assets/image_button.png">)
    end

    it "prevents XSS attacks" do
      html = form_for("/books") do |f|
        f.image_button "<script>alert('xss');</script>"
      end

      expect(html).to include %(<input type="image" src="">)
    end
  end

  #
  # FIELDSET
  #

  describe "#fieldset" do
    it "renders a fieldset" do
      html = render(<<~ERB)
        <%= form_for "/books" do |f| %>
          <%= f.fieldset do %>
            <%= tag.legend "Author" %>
            <%= f.label "author.name" %>
            <%= f.text_field "author.name" %>
          <% end %>
        <% end %>
      ERB

      expect(html).to include_html <<~HTML
        <fieldset>
          <legend>Author</legend>
          <label for="author-name">Name</label>
          <input type="text" name="author[name]" id="author-name" value="">
        </fieldset>
      HTML
    end
  end

  #
  # INPUT FIELDS
  #

  describe "#check_box" do
    it "renders" do
      html = form_for("/books") do |f|
        f.check_box "book.free_shipping"
      end

      expect(html).to include %(<input type="hidden" name="book[free_shipping]" value="0"><input type="checkbox" name="book[free_shipping]" id="book-free-shipping" value="1">)
    end

    it "allows to pass checked and unchecked value" do
      html = form_for("/books") do |f|
        f.check_box "book.free_shipping", checked_value: "true", unchecked_value: "false"
      end

      expect(html).to include %(<input type="hidden" name="book[free_shipping]" value="false"><input type="checkbox" name="book[free_shipping]" id="book-free-shipping" value="true">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.check_box "book.free_shipping", id: "shipping"
      end

      expect(html).to include %(<input type="hidden" name="book[free_shipping]" value="0"><input type="checkbox" name="book[free_shipping]" id="shipping" value="1">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.check_box "book.free_shipping", name: "book[free]"
      end

      expect(html).to include %(<input type="hidden" name="book[free]" value="0"><input type="checkbox" name="book[free]" id="book-free-shipping" value="1">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.check_box "book.free_shipping", class: "form-control"
      end

      expect(html).to include %(<input type="hidden" name="book[free_shipping]" value="0"><input type="checkbox" name="book[free_shipping]" id="book-free-shipping" value="1" class="form-control">)
    end

    it "doesn't render hidden field if 'value' attribute is specified" do
      html = form_for("/books") do |f|
        f.check_box "book.free_shipping", value: "ok"
      end

      expect(html).not_to include %(<input type="hidden" name="book[free_shipping]" value="0">)
      expect(html).to include %(<input type="checkbox" name="book[free_shipping]" id="book-free-shipping" value="ok">)
    end

    it "renders hidden field if 'value' attribute and 'unchecked_value' option are both specified" do
      html = form_for("/books") do |f|
        f.check_box "book.free_shipping", value: "yes", unchecked_value: "no"
      end

      expect(html).to include %(<input type="hidden" name="book[free_shipping]" value="no"><input type="checkbox" name="book[free_shipping]" id="book-free-shipping" value="yes">)
    end

    it "handles multiple checkboxes" do
      html = render(<<~ERB)
        <%= form_for("/books") do |f| %>
          <%= f.check_box "book.languages", name: "book[languages][]", value: "italian", id: nil %>
          <%= f.check_box "book.languages", name: "book[languages][]", value: "english", id: nil %>
        <% end %>
      ERB

      expect(html).to include_html <<~HTML
        <input type="checkbox" name="book[languages][]" value="italian">
        <input type="checkbox" name="book[languages][]" value="english">
      HTML
    end

    context "with filled params" do
      let(:params) { {book: {free_shipping: val}} }

      context "when the params value equals to check box value" do
        let(:val) { "1" }

        it "renders with 'checked' attribute" do
          html = form_for("/books") do |f|
            f.check_box "book.free_shipping"
          end

          expect(html).to include %(<input type="hidden" name="book[free_shipping]" value="0"><input type="checkbox" name="book[free_shipping]" id="book-free-shipping" value="1" checked="checked">)
        end
      end

      context "when the params value equals to the hidden field value" do
        let(:val) { "0" }

        it "renders without 'checked' attribute" do
          html = form_for("/books") do |f|
            f.check_box "book.free_shipping"
          end

          expect(html).to include %(<input type="hidden" name="book[free_shipping]" value="0"><input type="checkbox" name="book[free_shipping]" id="book-free-shipping" value="1">)
        end

        it "allows to override 'checked' attribute" do
          html = form_for("/books") do |f|
            f.check_box "book.free_shipping", checked: "checked"
          end

          expect(html).to include %(<input type="hidden" name="book[free_shipping]" value="0"><input type="checkbox" name="book[free_shipping]" id="book-free-shipping" value="1" checked="checked">)
        end
      end

      context "with a boolean argument" do
        let(:val) { true }

        it "renders with 'checked' attribute" do
          html = form_for("/books") do |f|
            f.check_box "book.free_shipping"
          end

          expect(html).to include %(<input type="hidden" name="book[free_shipping]" value="0"><input type="checkbox" name="book[free_shipping]" id="book-free-shipping" value="1" checked="checked">)
        end
      end

      context "when multiple params are present" do
        let(:params) { {book: {languages: ["italian"]}} }

        it "handles multiple checkboxes" do
          html = render(<<~ERB)
            <%= form_for("/books") do |f| %>
              <%= f.check_box "book.languages", name: "book[languages][]", value: "italian", id: nil %>
              <%= f.check_box "book.languages", name: "book[languages][]", value: "english", id: nil %>
            <% end %>
          ERB

          expect(html).to include_html <<~HTML
            <input type="checkbox" name="book[languages][]" value="italian" checked="checked">
            <input type="checkbox" name="book[languages][]" value="english">
          HTML
        end
      end

      context "checked_value is boolean" do
        let(:params) { {book: {free_shipping: "true"}} }

        it "renders with 'checked' attribute" do
          html = form_for("/books") do |f|
            f.check_box "book.free_shipping", checked_value: true
          end

          expect(html).to include %(<input type="checkbox" name="book[free_shipping]" id="book-free-shipping" value="true" checked="checked">)
        end
      end
    end

    context "automatic values" do
      context "checkbox" do
        context "value boolean, helper boolean, values differ" do
          let(:values) { {book: Struct.new(:free_shipping).new(false)} }

          it "renders" do
            html = form_for("/books", values: values) do |f|
              f.check_box "book.free_shipping", checked_value: true
            end

            expect(html).to include %(<input type="checkbox" name="book[free_shipping]" id="book-free-shipping" value="true">)
          end
        end
      end
    end
  end

  describe "#color_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.color_field "book.cover"
      end

      expect(html).to include %(<input type="color" name="book[cover]" id="book-cover" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.color_field "book.cover", id: "b-cover"
      end

      expect(html).to include %(<input type="color" name="book[cover]" id="b-cover" value="">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.color_field "book.cover", name: "cover"
      end

      expect(html).to include %(<input type="color" name="cover" id="book-cover" value="">)
    end

    it "allows to override 'value' attribute" do
      html = form_for("/books") do |f|
        f.color_field "book.cover", value: "#ffffff"
      end

      expect(html).to include %(<input type="color" name="book[cover]" id="book-cover" value="#ffffff">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.color_field "book.cover", class: "form-control"
      end

      expect(html).to include %(<input type="color" name="book[cover]" id="book-cover" value="" class="form-control">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:cover).new(val)} }
      let(:val) { "#d3397e" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.color_field "book.cover"
        end

        expect(html).to include %(<input type="color" name="book[cover]" id="book-cover" value="#{val}">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.color_field "book.cover", value: "#000000"
        end

        expect(html).to include %(<input type="color" name="book[cover]" id="book-cover" value="#000000">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {cover: val}} }
      let(:val) { "#d3397e" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.color_field "book.cover"
        end

        expect(html).to include %(<input type="color" name="book[cover]" id="book-cover" value="#{val}">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.color_field "book.cover", value: "#000000"
        end

        expect(html).to include %(<input type="color" name="book[cover]" id="book-cover" value="#000000">)
      end
    end
  end

  describe "#date_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.date_field "book.release_date"
      end

      expect(html).to include %(<input type="date" name="book[release_date]" id="book-release-date" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.date_field "book.release_date", id: "release-date"
      end

      expect(html).to include %(<input type="date" name="book[release_date]" id="release-date" value="">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.date_field "book.release_date", name: "release_date"
      end

      expect(html).to include %(<input type="date" name="release_date" id="book-release-date" value="">)
    end

    it "allows to override 'value' attribute" do
      html = form_for("/books") do |f|
        f.date_field "book.release_date", value: "2015-02-19"
      end

      expect(html).to include %(<input type="date" name="book[release_date]" id="book-release-date" value="2015-02-19">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.date_field "book.release_date", class: "form-control"
      end

      expect(html).to include %(<input type="date" name="book[release_date]" id="book-release-date" value="" class="form-control">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:release_date).new(val)} }
      let(:val)    { "2014-06-23" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.date_field "book.release_date"
        end

        expect(html).to include %(<input type="date" name="book[release_date]" id="book-release-date" value="#{val}">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.date_field "book.release_date", value: "2015-03-23"
        end

        expect(html).to include %(<input type="date" name="book[release_date]" id="book-release-date" value="2015-03-23">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {release_date: val}} }
      let(:val)    { "2014-06-23" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.date_field "book.release_date"
        end

        expect(html).to include %(<input type="date" name="book[release_date]" id="book-release-date" value="#{val}">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.date_field "book.release_date", value: "2015-03-23"
        end

        expect(html).to include %(<input type="date" name="book[release_date]" id="book-release-date" value="2015-03-23">)
      end
    end
  end

  describe "#datetime_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.datetime_field "book.published_at"
      end

      expect(html).to include %(<input type="datetime" name="book[published_at]" id="book-published-at" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.datetime_field "book.published_at", id: "published-timestamp"
      end

      expect(html).to include %(<input type="datetime" name="book[published_at]" id="published-timestamp" value="">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.datetime_field "book.published_at", name: "book[published][timestamp]"
      end

      expect(html).to include %(<input type="datetime" name="book[published][timestamp]" id="book-published-at" value="">)
    end

    it "allows to override 'value' attribute" do
      html = form_for("/books") do |f|
        f.datetime_field "book.published_at", value: "2015-02-19T12:50:36Z"
      end

      expect(html).to include %(<input type="datetime" name="book[published_at]" id="book-published-at" value="2015-02-19T12:50:36Z">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.datetime_field "book.published_at", class: "form-control"
      end

      expect(html).to include %(<input type="datetime" name="book[published_at]" id="book-published-at" value="" class="form-control">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:published_at).new(val)} }
      let(:val)    { "2015-02-19T12:56:31Z" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.datetime_field "book.published_at"
        end

        expect(html).to include %(<input type="datetime" name="book[published_at]" id="book-published-at" value="#{val}">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.datetime_field "book.published_at", value: "2015-02-19T12:50:36Z"
        end

        expect(html).to include %(<input type="datetime" name="book[published_at]" id="book-published-at" value="2015-02-19T12:50:36Z">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {published_at: val}} }
      let(:val)    { "2015-02-19T12:56:31Z" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.datetime_field "book.published_at"
        end

        expect(html).to include %(<input type="datetime" name="book[published_at]" id="book-published-at" value="#{val}">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.datetime_field "book.published_at", value: "2015-02-19T12:50:36Z"
        end

        expect(html).to include %(<input type="datetime" name="book[published_at]" id="book-published-at" value="2015-02-19T12:50:36Z">)
      end
    end
  end

  describe "#datetime_local_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.datetime_local_field "book.released_at"
      end

      expect(html).to include %(<input type="datetime-local" name="book[released_at]" id="book-released-at" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.datetime_local_field "book.released_at", id: "local-release-timestamp"
      end

      expect(html).to include %(<input type="datetime-local" name="book[released_at]" id="local-release-timestamp" value="">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.datetime_local_field "book.released_at", name: "book[release-timestamp]"
      end

      expect(html).to include %(<input type="datetime-local" name="book[release-timestamp]" id="book-released-at" value="">)
    end

    it "allows to override 'value' attribute" do
      html = form_for("/books") do |f|
        f.datetime_local_field "book.released_at", value: "2015-02-19T14:01:28+01:00"
      end

      expect(html).to include %(<input type="datetime-local" name="book[released_at]" id="book-released-at" value="2015-02-19T14:01:28+01:00">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.datetime_local_field "book.released_at", class: "form-control"
      end

      expect(html).to include %(<input type="datetime-local" name="book[released_at]" id="book-released-at" value="" class="form-control">)
    end

    context "with filled params" do
      let(:params) { {book: {released_at: val}} }
      let(:val)    { "2015-02-19T14:11:19+01:00" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.datetime_local_field "book.released_at"
        end

        expect(html).to include %(<input type="datetime-local" name="book[released_at]" id="book-released-at" value="#{val}">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.datetime_local_field "book.released_at", value: "2015-02-19T14:01:28+01:00"
        end

        expect(html).to include %(<input type="datetime-local" name="book[released_at]" id="book-released-at" value="2015-02-19T14:01:28+01:00">)
      end
    end
  end

  describe "#time_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.time_field "book.release_hour"
      end

      expect(html).to include %(<input type="time" name="book[release_hour]" id="book-release-hour" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.time_field "book.release_hour", id: "release-hour"
      end

      expect(html).to include %(<input type="time" name="book[release_hour]" id="release-hour" value="">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.time_field "book.release_hour", name: "release_hour"
      end

      expect(html).to include %(<input type="time" name="release_hour" id="book-release-hour" value="">)
    end

    it "allows to override 'value' attribute" do
      html = form_for("/books") do |f|
        f.time_field "book.release_hour", value: "00:00"
      end

      expect(html).to include %(<input type="time" name="book[release_hour]" id="book-release-hour" value="00:00">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.time_field "book.release_hour", class: "form-control"
      end

      expect(html).to include %(<input type="time" name="book[release_hour]" id="book-release-hour" value="" class="form-control">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:release_hour).new(val)} }
      let(:val)    { "18:30" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.time_field "book.release_hour"
        end

        expect(html).to include %(<input type="time" name="book[release_hour]" id="book-release-hour" value="#{val}">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.time_field "book.release_hour", value: "17:00"
        end

        expect(html).to include %(<input type="time" name="book[release_hour]" id="book-release-hour" value="17:00">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {release_hour: val}} }
      let(:val)    { "11:30" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.time_field "book.release_hour"
        end

        expect(html).to include %(<input type="time" name="book[release_hour]" id="book-release-hour" value="#{val}">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.time_field "book.release_hour", value: "8:15"
        end

        expect(html).to include %(<input type="time" name="book[release_hour]" id="book-release-hour" value="8:15">)
      end
    end
  end

  describe "#month_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.month_field "book.release_month"
      end

      expect(html).to include %(<input type="month" name="book[release_month]" id="book-release-month" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.month_field "book.release_month", id: "release-month"
      end

      expect(html).to include %(<input type="month" name="book[release_month]" id="release-month" value="">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.month_field "book.release_month", name: "release_month"
      end

      expect(html).to include %(<input type="month" name="release_month" id="book-release-month" value="">)
    end

    it "allows to override 'value' attribute" do
      html = form_for("/books") do |f|
        f.month_field "book.release_month", value: "2017-03"
      end

      expect(html).to include %(<input type="month" name="book[release_month]" id="book-release-month" value="2017-03">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.month_field "book.release_month", class: "form-control"
      end

      expect(html).to include %(<input type="month" name="book[release_month]" id="book-release-month" value="" class="form-control">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:release_month).new(val)} }
      let(:val)    { "2017-03" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.month_field "book.release_month"
        end

        expect(html).to include %(<input type="month" name="book[release_month]" id="book-release-month" value="#{val}">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.month_field "book.release_month", value: "2017-04"
        end

        expect(html).to include %(<input type="month" name="book[release_month]" id="book-release-month" value="2017-04">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {release_month: val}} }
      let(:val)    { "2017-10" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.month_field "book.release_month"
        end

        expect(html).to include %(<input type="month" name="book[release_month]" id="book-release-month" value="#{val}">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.month_field "book.release_month", value: "2017-04"
        end

        expect(html).to include %(<input type="month" name="book[release_month]" id="book-release-month" value="2017-04">)
      end
    end
  end

  describe "#week_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.week_field "book.release_week"
      end

      expect(html).to include %(<input type="week" name="book[release_week]" id="book-release-week" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.week_field "book.release_week", id: "release-week"
      end

      expect(html).to include %(<input type="week" name="book[release_week]" id="release-week" value="">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.week_field "book.release_week", name: "release_week"
      end

      expect(html).to include %(<input type="week" name="release_week" id="book-release-week" value="">)
    end

    it "allows to override 'value' attribute" do
      html = form_for("/books") do |f|
        f.week_field "book.release_week", value: "2017-W10"
      end

      expect(html).to include %(<input type="week" name="book[release_week]" id="book-release-week" value="2017-W10">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.week_field "book.release_week", class: "form-control"
      end

      expect(html).to include %(<input type="week" name="book[release_week]" id="book-release-week" value="" class="form-control">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:release_week).new(val)} }
      let(:val)    { "2017-W10" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.week_field "book.release_week"
        end

        expect(html).to include %(<input type="week" name="book[release_week]" id="book-release-week" value="#{val}">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.week_field "book.release_week", value: "2017-W31"
        end

        expect(html).to include %(<input type="week" name="book[release_week]" id="book-release-week" value="2017-W31">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {release_week: val}} }
      let(:val)    { "2017-W44" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.week_field "book.release_week"
        end

        expect(html).to include %(<input type="week" name="book[release_week]" id="book-release-week" value="#{val}">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.week_field "book.release_week", value: "2017-W07"
        end

        expect(html).to include %(<input type="week" name="book[release_week]" id="book-release-week" value="2017-W07">)
      end
    end
  end

  describe "#email_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.email_field "book.publisher_email"
      end

      expect(html).to include %(<input type="email" name="book[publisher_email]" id="book-publisher-email" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.email_field "book.publisher_email", id: "publisher-email"
      end

      expect(html).to include %(<input type="email" name="book[publisher_email]" id="publisher-email" value="">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.email_field "book.publisher_email", name: "book[email]"
      end

      expect(html).to include %(<input type="email" name="book[email]" id="book-publisher-email" value="">)
    end

    it "allows to override 'value' attribute" do
      html = form_for("/books") do |f|
        f.email_field "book.publisher_email", value: "publisher@example.org"
      end

      expect(html).to include %(<input type="email" name="book[publisher_email]" id="book-publisher-email" value="publisher@example.org">)
    end

    it "allows to specify 'multiple' attribute" do
      html = form_for("/books") do |f|
        f.email_field "book.publisher_email", multiple: true
      end

      expect(html).to include %(<input type="email" name="book[publisher_email]" id="book-publisher-email" value="" multiple="multiple">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.email_field "book.publisher_email", class: "form-control"
      end

      expect(html).to include %(<input type="email" name="book[publisher_email]" id="book-publisher-email" value="" class="form-control">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:publisher_email).new(val)} }
      let(:val)    { "maria@publisher.org" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.email_field "book.publisher_email"
        end

        expect(html).to include %(<input type="email" name="book[publisher_email]" id="book-publisher-email" value="maria@publisher.org">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.email_field "book.publisher_email", value: "publisher@example.org"
        end

        expect(html).to include %(<input type="email" name="book[publisher_email]" id="book-publisher-email" value="publisher@example.org">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {publisher_email: val}} }
      let(:val)    { "maria@publisher.org" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.email_field "book.publisher_email"
        end

        expect(html).to include %(<input type="email" name="book[publisher_email]" id="book-publisher-email" value="maria@publisher.org">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.email_field "book.publisher_email", value: "publisher@example.org"
        end

        expect(html).to include %(<input type="email" name="book[publisher_email]" id="book-publisher-email" value="publisher@example.org">)
      end
    end
  end

  describe "#url_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.url_field "book.website"
      end

      expect(html).to include %(<input type="url" name="book[website]" id="book-website" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.url_field "book.website", id: "website"
      end

      expect(html).to include %(<input type="url" name="book[website]" id="website" value="">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.url_field "book.website", name: "book[url]"
      end

      expect(html).to include %(<input type="url" name="book[url]" id="book-website" value="">)
    end

    it "allows to override 'value' attribute" do
      html = form_for("/books") do |f|
        f.url_field "book.website", value: "http://example.org"
      end

      expect(html).to include %(<input type="url" name="book[website]" id="book-website" value="http://example.org">)
    end

    it "allows to specify 'multiple' attribute" do
      html = form_for("/books") do |f|
        f.url_field "book.website", multiple: true
      end

      expect(html).to include %(<input type="url" name="book[website]" id="book-website" value="" multiple="multiple">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.url_field "book.website", class: "form-control"
      end

      expect(html).to include %(<input type="url" name="book[website]" id="book-website" value="" class="form-control">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:website).new(val)} }
      let(:val)    { "http://publisher.org" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.url_field "book.website"
        end

        expect(html).to include %(<input type="url" name="book[website]" id="book-website" value="http://publisher.org">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.url_field "book.website", value: "https://www.example.org"
        end

        expect(html).to include %(<input type="url" name="book[website]" id="book-website" value="https://www.example.org">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {website: val}} }
      let(:val)    { "http://publisher.org" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.url_field "book.website"
        end

        expect(html).to include %(<input type="url" name="book[website]" id="book-website" value="http://publisher.org">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.url_field "book.website", value: "http://example.org"
        end

        expect(html).to include %(<input type="url" name="book[website]" id="book-website" value="http://example.org">)
      end
    end

    context "with escape url" do
      let(:values) { {book: Struct.new(:website).new(val)} }
      let(:val)    { %("onclick=javascript:alert('xss')) }

      it "renders with automatic value" do
        html = form_for("/books", values: values) do |f|
          f.url_field "book.website"
        end

        expect(html).to include %(<input type="url" name="book[website]" id="book-website" value="">)
      end

      it "renders with explicit value" do
        html = form_for("/books", values: values) do |f|
          f.url_field "book.website", value: val
        end

        expect(html).to include %(<input type="url" name="book[website]" id="book-website" value="">)
      end
    end
  end

  describe "#tel_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.tel_field "book.publisher_telephone"
      end

      expect(html).to include %(<input type="tel" name="book[publisher_telephone]" id="book-publisher-telephone" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.tel_field "book.publisher_telephone", id: "publisher-telephone"
      end

      expect(html).to include %(<input type="tel" name="book[publisher_telephone]" id="publisher-telephone" value="">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.tel_field "book.publisher_telephone", name: "book[telephone]"
      end

      expect(html).to include %(<input type="tel" name="book[telephone]" id="book-publisher-telephone" value="">)
    end

    it "allows to override 'value' attribute" do
      html = form_for("/books") do |f|
        f.tel_field "book.publisher_telephone", value: "publisher@example.org"
      end

      expect(html).to include %(<input type="tel" name="book[publisher_telephone]" id="book-publisher-telephone" value="publisher@example.org">)
    end

    it "allows to specify 'multiple' attribute" do
      html = form_for("/books") do |f|
        f.tel_field "book.publisher_telephone", multiple: true
      end

      expect(html).to include %(<input type="tel" name="book[publisher_telephone]" id="book-publisher-telephone" value="" multiple="multiple">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.tel_field "book.publisher_telephone", class: "form-control"
      end

      expect(html).to include %(<input type="tel" name="book[publisher_telephone]" id="book-publisher-telephone" value="" class="form-control">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:publisher_telephone).new(val)} }
      let(:val)    { "maria@publisher.org" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.tel_field "book.publisher_telephone"
        end

        expect(html).to include %(<input type="tel" name="book[publisher_telephone]" id="book-publisher-telephone" value="maria@publisher.org">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.tel_field "book.publisher_telephone", value: "publisher@example.org"
        end

        expect(html).to include %(<input type="tel" name="book[publisher_telephone]" id="book-publisher-telephone" value="publisher@example.org">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {publisher_telephone: val}} }
      let(:val)    { "maria@publisher.org" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.tel_field "book.publisher_telephone"
        end

        expect(html).to include %(<input type="tel" name="book[publisher_telephone]" id="book-publisher-telephone" value="maria@publisher.org">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.tel_field "book.publisher_telephone", value: "publisher@example.org"
        end

        expect(html).to include %(<input type="tel" name="book[publisher_telephone]" id="book-publisher-telephone" value="publisher@example.org">)
      end
    end
  end

  describe "#file_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.file_field "book.image_cover"
      end

      expect(html).to include %(<input type="file" name="book[image_cover]" id="book-image-cover">)
    end

    it "sets 'enctype' attribute to the form" do
      html = form_for("/books") do |f|
        f.file_field "book.image_cover"
      end

      expect(html).to include %(<form action="/books" enctype="multipart/form-data" accept-charset="utf-8" method="POST">)
    end

    it "sets 'enctype' attribute to the form when there are nested fields" do
      html = form_for("/books") do |f|
        f.fields_for("images") do
          f.file_field("cover")
        end
      end

      expect(html).to include %(<form action="/books" enctype="multipart/form-data" accept-charset="utf-8" method="POST">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.file_field "book.image_cover", id: "book-cover"
      end

      expect(html).to include %(<input type="file" name="book[image_cover]" id="book-cover">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.file_field "book.image_cover", name: "book[cover]"
      end

      expect(html).to include %(<input type="file" name="book[cover]" id="book-image-cover">)
    end

    it "allows to specify 'multiple' attribute" do
      html = form_for("/books") do |f|
        f.file_field "book.image_cover", multiple: true
      end

      expect(html).to include %(<input type="file" name="book[image_cover]" id="book-image-cover" multiple="multiple">)
    end

    it "allows to specify single value for 'accept' attribute" do
      html = form_for("/books") do |f|
        f.file_field "book.image_cover", accept: "application/pdf"
      end

      expect(html).to include %(<input type="file" name="book[image_cover]" id="book-image-cover" accept="application/pdf">)
    end

    it "allows to specify multiple values for 'accept' attribute" do
      html = form_for("/books") do |f|
        f.file_field "book.image_cover", accept: "image/png,image/jpg"
      end

      expect(html).to include %(<input type="file" name="book[image_cover]" id="book-image-cover" accept="image/png,image/jpg">)
    end

    it "allows to specify multiple values (array) for 'accept' attribute" do
      html = form_for("/books") do |f|
        f.file_field "book.image_cover", accept: ["image/png", "image/jpg"]
      end

      expect(html).to include %(<input type="file" name="book[image_cover]" id="book-image-cover" accept="image/png,image/jpg">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:image_cover).new(val)} }
      let(:val)    { "image" }

      it "ignores value" do
        html = form_for("/books", values: values) do |f|
          f.file_field "book.image_cover"
        end

        expect(html).to include %(<input type="file" name="book[image_cover]" id="book-image-cover">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {image_cover: val}} }
      let(:val)    { "image" }

      it "ignores value" do
        html = form_for("/books") do |f|
          f.file_field "book.image_cover"
        end

        expect(html).to include %(<input type="file" name="book[image_cover]" id="book-image-cover">)
      end
    end
  end

  describe "#hidden_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.hidden_field "book.author_id"
      end

      expect(html).to include %(<input type="hidden" name="book[author_id]" id="book-author-id" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.hidden_field "book.author_id", id: "author-id"
      end

      expect(html).to include %(<input type="hidden" name="book[author_id]" id="author-id" value="">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.hidden_field "book.author_id", name: "book[author]"
      end

      expect(html).to include %(<input type="hidden" name="book[author]" id="book-author-id" value="">)
    end

    it "allows to override 'value' attribute" do
      html = form_for("/books") do |f|
        f.hidden_field "book.author_id", value: "23"
      end

      expect(html).to include %(<input type="hidden" name="book[author_id]" id="book-author-id" value="23">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.hidden_field "book.author_id", class: "form-details"
      end

      expect(html).to include %(<input type="hidden" name="book[author_id]" id="book-author-id" value="" class="form-details">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:author_id).new(val)} }
      let(:val)    { "1" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.hidden_field "book.author_id"
        end

        expect(html).to include %(<input type="hidden" name="book[author_id]" id="book-author-id" value="1">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.hidden_field "book.author_id", value: "23"
        end

        expect(html).to include %(<input type="hidden" name="book[author_id]" id="book-author-id" value="23">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {author_id: val}} }
      let(:val)    { "1" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.hidden_field "book.author_id"
        end

        expect(html).to include %(<input type="hidden" name="book[author_id]" id="book-author-id" value="1">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.hidden_field "book.author_id", value: "23"
        end

        expect(html).to include %(<input type="hidden" name="book[author_id]" id="book-author-id" value="23">)
      end
    end
  end

  describe "#number_field" do
    it "renders the element" do
      html = form_for("/books") do |f|
        f.number_field "book.percent_read"
      end

      expect(html).to include %(<input type="number" name="book[percent_read]" id="book-percent-read" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.number_field "book.percent_read", id: "percent-read"
      end

      expect(html).to include %(<input type="number" name="book[percent_read]" id="percent-read" value="">)
    end

    it "allows to override the 'name' attribute" do
      html = form_for("/books") do |f|
        f.number_field "book.percent_read", name: "book[read]"
      end

      expect(html).to include %(<input type="number" name="book[read]" id="book-percent-read" value="">)
    end

    it "allows to override the 'value' attribute" do
      html = form_for("/books") do |f|
        f.number_field "book.percent_read", value: "99"
      end

      expect(html).to include %(<input type="number" name="book[percent_read]" id="book-percent-read" value="99">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.number_field "book.percent_read", class: "form-control"
      end

      expect(html).to include %(<input type="number" name="book[percent_read]" id="book-percent-read" value="" class="form-control">)
    end

    it "allows to specify a 'min' attribute" do
      html = form_for("/books") do |f|
        f.number_field "book.percent_read", min: 0
      end

      expect(html).to include %(<input type="number" name="book[percent_read]" id="book-percent-read" value="" min="0">)
    end

    it "allows to specify a 'max' attribute" do
      html = form_for("/books") do |f|
        f.number_field "book.percent_read", max: 100
      end

      expect(html).to include %(<input type="number" name="book[percent_read]" id="book-percent-read" value="" max="100">)
    end

    it "allows to specify a 'step' attribute" do
      html = form_for("/books") do |f|
        f.number_field "book.percent_read", step: 5
      end

      expect(html).to include %(<input type="number" name="book[percent_read]" id="book-percent-read" value="" step="5">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:percent_read).new(val)} }
      let(:val)    { 95 }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.number_field "book.percent_read"
        end

        expect(html).to include %(<input type="number" name="book[percent_read]" id="book-percent-read" value="95">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.number_field "book.percent_read", value: 50
        end

        expect(html).to include %(<input type="number" name="book[percent_read]" id="book-percent-read" value="50">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {percent_read: val}} }
      let(:val)    { 95 }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.number_field "book.percent_read"
        end

        expect(html).to include %(<input type="number" name="book[percent_read]" id="book-percent-read" value="95">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.number_field "book.percent_read", value: 50
        end

        expect(html).to include %(<input type="number" name="book[percent_read]" id="book-percent-read" value="50">)
      end
    end
  end

  describe "#range_field" do
    it "renders the element" do
      html = form_for("/books") do |f|
        f.range_field "book.discount_percentage"
      end

      expect(html).to include %(<input type="range" name="book[discount_percentage]" id="book-discount-percentage" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.range_field "book.discount_percentage", id: "discount-percentage"
      end

      expect(html).to include %(<input type="range" name="book[discount_percentage]" id="discount-percentage" value="">)
    end

    it "allows to override the 'name' attribute" do
      html = form_for("/books") do |f|
        f.range_field "book.discount_percentage", name: "book[read]"
      end

      expect(html).to include %(<input type="range" name="book[read]" id="book-discount-percentage" value="">)
    end

    it "allows to override the 'value' attribute" do
      html = form_for("/books") do |f|
        f.range_field "book.discount_percentage", value: "99"
      end

      expect(html).to include %(<input type="range" name="book[discount_percentage]" id="book-discount-percentage" value="99">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.range_field "book.discount_percentage", class: "form-control"
      end

      expect(html).to include %(<input type="range" name="book[discount_percentage]" id="book-discount-percentage" value="" class="form-control">)
    end

    it "allows to specify a 'min' attribute" do
      html = form_for("/books") do |f|
        f.range_field "book.discount_percentage", min: 0
      end

      expect(html).to include %(<input type="range" name="book[discount_percentage]" id="book-discount-percentage" value="" min="0">)
    end

    it "allows to specify a 'max' attribute" do
      html = form_for("/books") do |f|
        f.range_field "book.discount_percentage", max: 100
      end

      expect(html).to include %(<input type="range" name="book[discount_percentage]" id="book-discount-percentage" value="" max="100">)
    end

    it "allows to specify a 'step' attribute" do
      html = form_for("/books") do |f|
        f.range_field "book.discount_percentage", step: 5
      end

      expect(html).to include %(<input type="range" name="book[discount_percentage]" id="book-discount-percentage" value="" step="5">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:discount_percentage).new(val)} }
      let(:val)    { 95 }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.range_field "book.discount_percentage"
        end

        expect(html).to include %(<input type="range" name="book[discount_percentage]" id="book-discount-percentage" value="95">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.range_field "book.discount_percentage", value: 50
        end

        expect(html).to include %(<input type="range" name="book[discount_percentage]" id="book-discount-percentage" value="50">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {discount_percentage: val}} }
      let(:val)    { 95 }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.range_field "book.discount_percentage"
        end

        expect(html).to include %(<input type="range" name="book[discount_percentage]" id="book-discount-percentage" value="95">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.range_field "book.discount_percentage", value: 50
        end

        expect(html).to include %(<input type="range" name="book[discount_percentage]" id="book-discount-percentage" value="50">)
      end
    end
  end

  describe "#text_area" do
    it "renders the element" do
      html = form_for("/books") do |f|
        f.text_area "book.description"
      end

      expect(html).to include %(<textarea name="book[description]" id="book-description">\n</textarea>)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.text_area "book.description", nil, id: "desc"
      end

      expect(html).to include %(<textarea name="book[description]" id="desc">\n</textarea>)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.text_area "book.description", nil, name: "book[desc]"
      end

      expect(html).to include %(<textarea name="book[desc]" id="book-description">\n</textarea>)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.text_area "book.description", nil, class: "form-control", cols: "5"
      end

      expect(html).to include %(<textarea name="book[description]" id="book-description" class="form-control" cols="5">\n</textarea>)
    end

    it "allows to omit content" do
      html = form_for("/books") do |f|
        f.text_area "book.description", class: "form-control", cols: "5"
      end

      expect(html).to include %(<textarea name="book[description]" id="book-description" class="form-control" cols="5">\n</textarea>)
    end

    it "allows to omit content, by accepting Hash serializable options" do
      options = {class: "form-control", cols: 5}

      html = form_for("/books") do |f|
        f.text_area "book.description", options
      end

      expect(html).to include %(<textarea name="book[description]" id="book-description" class="form-control" cols="5">\n</textarea>)
    end

    context "set content explicitly" do
      let(:content) { "A short description of the book" }

      it "allows to set content" do
        html = form_for("/books") do |f|
          f.text_area "book.description", content
        end

        expect(html).to include %(<textarea name="book[description]" id="book-description">\n#{content}</textarea>)
      end
    end

    context "with values" do
      let(:values) { {book: Struct.new(:description).new(val)} }
      let(:val) { "A short description of the book" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.text_area "book.description"
        end

        expect(html).to include %(<textarea name="book[description]" id="book-description">\n#{val}</textarea>)
      end

      it "renders with value, when only attributes are specified" do
        html = form_for("/books", values: values) do |f|
          f.text_area "book.description", class: "form-control"
        end

        expect(html).to include %(<textarea name="book[description]" id="book-description" class="form-control">\n#{val}</textarea>)
      end

      it "allows to override value" do
        html = form_for("/books", values: values) do |f|
          f.text_area "book.description", "Just a simple description"
        end

        expect(html).to include %(<textarea name="book[description]" id="book-description">\nJust a simple description</textarea>)
      end

      it "forces blank value" do
        html = form_for("/books", values: values) do |f|
          f.text_area "book.description", ""
        end

        expect(html).to include %(<textarea name="book[description]" id="book-description">\n</textarea>)
      end

      it "forces blank value, when also attributes are specified" do
        html = form_for("/books", values: values) do |f|
          f.text_area "book.description", "", class: "form-control"
        end

        expect(html).to include %(<textarea name="book[description]" id="book-description" class="form-control">\n</textarea>)
      end
    end

    context "with filled params" do
      let(:params) { {book: {description: val}} }
      let(:val) { "A short description of the book" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.text_area "book.description"
        end

        expect(html).to include %(<textarea name="book[description]" id="book-description">\n#{val}</textarea>)
      end

      it "renders with value, when only attributes are specified" do
        html = form_for("/books") do |f|
          f.text_area "book.description", class: "form-control"
        end

        expect(html).to include %(<textarea name="book[description]" id="book-description" class="form-control">\n#{val}</textarea>)
      end

      it "allows to override value" do
        html = form_for("/books") do |f|
          f.text_area "book.description", "Just a simple description"
        end

        expect(html).to include %(<textarea name="book[description]" id="book-description">\nJust a simple description</textarea>)
      end

      it "forces blank value" do
        html = form_for("/books") do |f|
          f.text_area "book.description", ""
        end

        expect(html).to include %(<textarea name="book[description]" id="book-description">\n</textarea>)
      end

      it "forces blank value, when also attributes are specified" do
        html = form_for("/books") do |f|
          f.text_area "book.description", "", class: "form-control"
        end

        expect(html).to include %(<textarea name="book[description]" id="book-description" class="form-control">\n</textarea>)
      end
    end
  end

  describe "#text_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.text_field "book.title"
      end

      expect(html).to include %(<input type="text" name="book[title]" id="book-title" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.text_field "book.title", id: "book-short-title"
      end

      expect(html).to include %(<input type="text" name="book[title]" id="book-short-title" value="">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.text_field "book.title", name: "book[short_title]"
      end

      expect(html).to include %(<input type="text" name="book[short_title]" id="book-title" value="">)
    end

    it "allows to override 'value' attribute" do
      html = form_for("/books") do |f|
        f.text_field "book.title", value: "Refactoring"
      end

      expect(html).to include %(<input type="text" name="book[title]" id="book-title" value="Refactoring">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.text_field "book.title", class: "form-control"
      end

      expect(html).to include %(<input type="text" name="book[title]" id="book-title" value="" class="form-control">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:title).new(val)} }
      let(:val)    { "Learn some <html>!" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.text_field "book.title"
        end

        expect(html).to include %(<input type="text" name="book[title]" id="book-title" value="Learn some &lt;html&gt;!">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.text_field "book.title", value: "DDD"
        end

        expect(html).to include %(<input type="text" name="book[title]" id="book-title" value="DDD">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {title: val}} }
      let(:val)    { "Learn some <html>!" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.text_field "book.title"
        end

        expect(html).to include %(<input type="text" name="book[title]" id="book-title" value="Learn some &lt;html&gt;!">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.text_field "book.title", value: "DDD"
        end

        expect(html).to include %(<input type="text" name="book[title]" id="book-title" value="DDD">)
      end
    end
  end

  describe "#search_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.search_field "book.search_title"
      end

      expect(html).to include %(<input type="search" name="book[search_title]" id="book-search-title" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.search_field "book.search_title", id: "book-short-title"
      end

      expect(html).to include %(<input type="search" name="book[search_title]" id="book-short-title" value="">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.search_field "book.search_title", name: "book[short_title]"
      end

      expect(html).to include %(<input type="search" name="book[short_title]" id="book-search-title" value="">)
    end

    it "allows to override 'value' attribute" do
      html = form_for("/books") do |f|
        f.search_field "book.search_title", value: "Refactoring"
      end

      expect(html).to include %(<input type="search" name="book[search_title]" id="book-search-title" value="Refactoring">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.search_field "book.search_title", class: "form-control"
      end

      expect(html).to include %(<input type="search" name="book[search_title]" id="book-search-title" value="" class="form-control">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:search_title).new(val)} }
      let(:val)    { "PPoEA" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.search_field "book.search_title"
        end

        expect(html).to include %(<input type="search" name="book[search_title]" id="book-search-title" value="PPoEA">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.search_field "book.search_title", value: "DDD"
        end

        expect(html).to include %(<input type="search" name="book[search_title]" id="book-search-title" value="DDD">)
      end
    end

    context "with filled params" do
      let(:params) { {book: {search_title: val}} }
      let(:val)    { "PPoEA" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.search_field "book.search_title"
        end

        expect(html).to include %(<input type="search" name="book[search_title]" id="book-search-title" value="PPoEA">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.search_field "book.search_title", value: "DDD"
        end

        expect(html).to include %(<input type="search" name="book[search_title]" id="book-search-title" value="DDD">)
      end
    end
  end

  describe "#password_field" do
    it "renders" do
      html = form_for("/books") do |f|
        f.password_field "signup.password"
      end

      expect(html).to include %(<input type="password" name="signup[password]" id="signup-password" value="">)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.password_field "signup.password", id: "signup-pass"
      end

      expect(html).to include %(<input type="password" name="signup[password]" id="signup-pass" value="">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.password_field "signup.password", name: "password"
      end

      expect(html).to include %(<input type="password" name="password" id="signup-password" value="">)
    end

    it "allows to override 'value' attribute" do
      html = form_for("/books") do |f|
        f.password_field "signup.password", value: "topsecret"
      end

      expect(html).to include %(<input type="password" name="signup[password]" id="signup-password" value="topsecret">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.password_field "signup.password", class: "form-control"
      end

      expect(html).to include %(<input type="password" name="signup[password]" id="signup-password" value="" class="form-control">)
    end

    context "with values" do
      let(:values) { {signup: Struct.new(:password).new(val)} }
      let(:val)    { "secret" }

      it "ignores value" do
        html = form_for("/books", values: values) do |f|
          f.password_field "signup.password"
        end

        expect(html).to include %(<input type="password" name="signup[password]" id="signup-password" value="">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books", values: values) do |f|
          f.password_field "signup.password", value: "123"
        end

        expect(html).to include %(<input type="password" name="signup[password]" id="signup-password" value="123">)
      end
    end

    context "with filled params" do
      let(:params) { {signup: {password: val}} }
      let(:val)    { "secret" }

      it "ignores value" do
        html = form_for("/books") do |f|
          f.password_field "signup.password"
        end

        expect(html).to include %(<input type="password" name="signup[password]" id="signup-password" value="">)
      end

      it "allows to override 'value' attribute" do
        html = form_for("/books") do |f|
          f.password_field "signup.password", value: "123"
        end

        expect(html).to include %(<input type="password" name="signup[password]" id="signup-password" value="123">)
      end
    end
  end

  describe "#radio_button" do
    it "renders" do
      html = form_for("/books") do |f|
        f.radio_button("book.category", "Fiction") +
          f.radio_button("book.category", "Non-Fiction")
      end

      expect(html).to include %(<input type="radio" name="book[category]" value="Fiction"><input type="radio" name="book[category]" value="Non-Fiction">)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.radio_button("book.category", "Fiction", name: "category_name") +
          f.radio_button("book.category", "Non-Fiction", name: "category_name")
      end

      expect(html).to include %(<input type="radio" name="category_name" value="Fiction"><input type="radio" name="category_name" value="Non-Fiction">)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.radio_button("book.category", "Fiction", class: "form-control") +
          f.radio_button("book.category", "Non-Fiction", class: "radio-button")
      end

      expect(html).to include %(<input type="radio" name="book[category]" value="Fiction" class="form-control"><input type="radio" name="book[category]" value="Non-Fiction" class="radio-button">)
    end

    context "with values" do
      let(:values) { {book: Struct.new(:category).new(val)} }
      let(:val)    { "Non-Fiction" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.radio_button("book.category", "Fiction") +
            f.radio_button("book.category", "Non-Fiction")
        end

        expect(html).to include %(<input type="radio" name="book[category]" value="Fiction"><input type="radio" name="book[category]" value="Non-Fiction" checked="checked">)
      end
    end

    context "with filled params" do
      context "string value" do
        let(:params) { {book: {category: val}} }
        let(:val)    { "Non-Fiction" }

        it "renders with value" do
          html = form_for("/books") do |f|
            f.radio_button("book.category", "Fiction") +
              f.radio_button("book.category", "Non-Fiction")
          end

          expect(html).to include %(<input type="radio" name="book[category]" value="Fiction"><input type="radio" name="book[category]" value="Non-Fiction" checked="checked">)
        end
      end

      context "decimal value" do
        let(:params) { {book: {price: val}} }
        let(:val)    { "20.0" }

        it "renders with value" do
          html = form_for("/books") do |f|
            f.radio_button("book.price", 10.0) +
              f.radio_button("book.price", 20.0)
          end

          expect(html).to include %(<input type="radio" name="book[price]" value="10.0"><input type="radio" name="book[price]" value="20.0" checked="checked">)
        end
      end
    end
  end

  describe "#select" do
    let(:option_values) { {"Italy" => "it", "United States" => "us"} }

    it "renders" do
      html = form_for("/books") do |f|
        f.select "book.store", option_values
      end

      expect(html).to include %(<select name="book[store]" id="book-store"><option value="it">Italy</option><option value="us">United States</option></select>)
    end

    it "allows to override 'id' attribute" do
      html = form_for("/books") do |f|
        f.select "book.store", option_values, id: "store"
      end

      expect(html).to include %(<select name="book[store]" id="store"><option value="it">Italy</option><option value="us">United States</option></select>)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.select "book.store", option_values, name: "store"
      end

      expect(html).to include %(<select name="store" id="book-store"><option value="it">Italy</option><option value="us">United States</option></select>)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.select "book.store", option_values, class: "form-control"
      end

      expect(html).to include %(<select name="book[store]" id="book-store" class="form-control"><option value="it">Italy</option><option value="us">United States</option></select>)
    end

    it "allows to specify HTML attributes for options" do
      html = form_for("/books") do |f|
        f.select "book.store", option_values, options: {class: "form-option"}
      end

      expect(html).to include %(<select name="book[store]" id="book-store"><option value="it" class="form-option">Italy</option><option value="us" class="form-option">United States</option></select>)
    end

    context "with option 'multiple'" do
      it "renders" do
        html = form_for("/books") do |f|
          f.select "book.store", option_values, multiple: true
        end

        expect(html).to include %(<select name="book[store][]" id="book-store" multiple="multiple"><option value="it">Italy</option><option value="us">United States</option></select>)
      end

      it "allows to select values" do
        html = form_for("/books") do |f|
          f.select "book.store", option_values, multiple: true, options: {selected: %w[it us]}
        end

        expect(html).to include %(<select name="book[store][]" id="book-store" multiple="multiple"><option value="it" selected="selected">Italy</option><option value="us" selected="selected">United States</option></select>)
      end
    end

    context "with values an structured Array of values" do
      let(:option_values) { [%w[Italy it], ["United States", "us"]] }

      it "renders" do
        html = form_for("/books") do |f|
          f.select "book.store", option_values
        end

        expect(html).to include %(<select name="book[store]" id="book-store"><option value="it">Italy</option><option value="us">United States</option></select>)
      end

      context "and filled params" do
        let(:params) { {book: {store: val}} }
        let(:val)    { "it" }

        it "renders with value" do
          html = form_for("/books") do |f|
            f.select "book.store", option_values
          end

          expect(html).to include %(<select name="book[store]" id="book-store"><option value="it" selected="selected">Italy</option><option value="us">United States</option></select>)
        end
      end

      context "and repeated values" do
        let(:option_values) { [%w[Italy it], ["United States", "us"], %w[Italy it]] }

        it "renders" do
          html = form_for("/books") do |f|
            f.select "book.store", option_values
          end

          expect(html).to include %(<select name="book[store]" id="book-store"><option value="it">Italy</option><option value="us">United States</option><option value="it">Italy</option></select>)
        end
      end
    end

    context "with values an Array of objects" do
      let(:values) { [Store.new("it", "Italy"), Store.new("us", "United States")] }

      it "renders" do
        html = form_for("/books") do |f|
          f.select "book.store", option_values
        end

        expect(html).to include %(<select name="book[store]" id="book-store"><option value="it">Italy</option><option value="us">United States</option></select>)
      end

      context "and filled params" do
        let(:params) { {book: {store: val}} }
        let(:val)    { "it" }

        it "renders with value" do
          html = form_for("/books") do |f|
            f.select "book.store", option_values
          end

          expect(html).to include %(<select name="book[store]" id="book-store"><option value="it" selected="selected">Italy</option><option value="us">United States</option></select>)
        end
      end
    end

    context "with values" do
      let(:values) { {book: Struct.new(:store).new(val)} }
      let(:val)    { "it" }

      it "renders with value" do
        html = form_for("/books", values: values) do |f|
          f.select "book.store", option_values
        end

        expect(html).to include %(<select name="book[store]" id="book-store"><option value="it" selected="selected">Italy</option><option value="us">United States</option></select>)
      end
    end

    context "with filled params" do
      let(:params) { {book: {store: val}} }
      let(:val)    { "it" }

      it "renders with value" do
        html = form_for("/books") do |f|
          f.select "book.store", option_values
        end

        expect(html).to include %(<select name="book[store]" id="book-store"><option value="it" selected="selected">Italy</option><option value="us">United States</option></select>)
      end
    end

    context "with prompt option" do
      it "allows string" do
        html = form_for("/books") do |f|
          f.select "book.store", option_values, options: {prompt: "Select a store"}
        end

        expect(html).to include %(<select name="book[store]" id="book-store"><option disabled="disabled">Select a store</option><option value="it">Italy</option><option value="us">United States</option></select>)
      end

      it "allows blank string" do
        html = form_for("/books") do |f|
          f.select "book.store", option_values, options: {prompt: ""}
        end

        expect(html).to include %(<select name="book[store]" id="book-store"><option disabled="disabled"></option><option value="it">Italy</option><option value="us">United States</option></select>)
      end

      context "with values" do
        let(:values) { {book: Struct.new(:store).new(val)} }
        let(:val)    { "it" }

        it "renders with value" do
          html = form_for("/books", values: values) do |f|
            f.select "book.store", option_values, options: {prompt: "Select a store"}
          end

          expect(html).to include %(<select name="book[store]" id="book-store"><option disabled="disabled">Select a store</option><option value="it" selected="selected">Italy</option><option value="us">United States</option></select>)
        end
      end

      context "with filled params" do
        context "string values" do
          let(:params) { {book: {store: val}} }
          let(:val)    { "it" }

          it "renders with value" do
            html = form_for("/books") do |f|
              f.select "book.store", option_values, options: {prompt: "Select a store"}
            end

            expect(html).to include %(<select name="book[store]" id="book-store"><option disabled="disabled">Select a store</option><option value="it" selected="selected">Italy</option><option value="us">United States</option></select>)
          end
        end

        context "integer values" do
          let(:values) { {"Brave new world" => 1, "Solaris" => 2} }
          let(:params) { {bookshelf: {book: val}} }
          let(:val)    { "1" }

          it "renders" do
            html = form_for("/books") do |f|
              f.select "bookshelf.book", values
            end

            expect(html).to include %(<select name="bookshelf[book]" id="bookshelf-book"><option value="1" selected="selected">Brave new world</option><option value="2">Solaris</option></select>)
          end
        end
      end
    end

    context "with selected attribute" do
      let(:params) { {book: {store: val}} }
      let(:val)    { "it" }

      it "sets the selected attribute" do
        html = form_for("/books") do |f|
          f.select "book.store", option_values, options: {selected: val}
        end

        expect(html).to include %(<select name="book[store]" id="book-store"><option value="it" selected="selected">Italy</option><option value="us">United States</option></select>)
      end
    end

    context "with nil as a value" do
      let(:option_values) { {"Italy" => "it", "United States" => "us", "N/A" => nil} }

      it "sets nil option as selected by default" do
        html = form_for("/books") do |f|
          f.select "book.store", option_values
        end

        expect(html).to include %(<select name="book[store]" id="book-store"><option value="it">Italy</option><option value="us">United States</option><option selected="selected">N/A</option></select>)
      end

      it "set as selected the option with nil value" do
        html = form_for("/books") do |f|
          f.select "book.store", option_values, options: {selected: nil}
        end

        expect(html).to include %(<select name="book[store]" id="book-store"><option value="it">Italy</option><option value="us">United States</option><option selected="selected">N/A</option></select>)
      end

      it "set as selected the option with a value" do
        html = form_for("/books") do |f|
          f.select "book.store", option_values, options: {selected: "it"}
        end

        expect(html).to include %(<select name="book[store]" id="book-store"><option value="it" selected="selected">Italy</option><option value="us">United States</option><option>N/A</option></select>)
      end

      it "allows to force the selection of none" do
        html = form_for("/books") do |f|
          f.select "book.store", option_values, options: {selected: "none"}
        end

        expect(html).to include %(<select name="book[store]" id="book-store"><option value="it">Italy</option><option value="us">United States</option><option>N/A</option></select>)
      end

      context "with values" do
        let(:values)        { {book: Struct.new(:category).new(val)} }
        let(:option_values) { {"N/A" => nil, "Horror" => "horror", "SciFy" => "scify"} }
        let(:val)           { "horror" }

        it "sets correct value as selected" do
          html = form_for("/books", values: values) do |f|
            f.select "book.category", option_values
          end

          expect(html).to include %(<form action="/books" accept-charset="utf-8" method="POST"><select name="book[category]" id="book-category"><option>N/A</option><option value="horror" selected="selected">Horror</option><option value="scify">SciFy</option></select></form>)
        end
      end

      context "with non String values" do
        let(:values)        { {book: Struct.new(:category).new(val)} }
        let(:option_values) { {"Horror" => "1", "SciFy" => "2"} }
        let(:val)           { 1 }

        it "sets correct value as selected" do
          html = form_for("/books", values: values) do |f|
            f.select "book.category", option_values
          end

          expect(html).to include %(<form action="/books" accept-charset="utf-8" method="POST"><select name="book[category]" id="book-category"><option value="1" selected="selected">Horror</option><option value="2">SciFy</option></select></form>)
        end
      end
    end
  end

  describe "#datalist" do
    let(:values) { ["Italy", "United States"] }

    it "renders" do
      html = form_for("/books") do |f|
        f.datalist "book.store", values, "books"
      end

      expect(html).to include %(<input type="text" name="book[store]" id="book-store" value="" list="books"><datalist id="books"><option value="Italy"></option><option value="United States"></option></datalist>)
    end

    it "just allows to override 'id' attribute of the text input" do
      html = form_for("/books") do |f|
        f.datalist "book.store", values, "books", id: "store"
      end

      expect(html).to include %(<input type="text" name="book[store]" id="store" value="" list="books"><datalist id="books"><option value="Italy"></option><option value="United States"></option></datalist>)
    end

    it "allows to override 'name' attribute" do
      html = form_for("/books") do |f|
        f.datalist "book.store", values, "books", name: "store"
      end

      expect(html).to include %(<input type="text" name="store" id="book-store" value="" list="books"><datalist id="books"><option value="Italy"></option><option value="United States"></option></datalist>)
    end

    it "allows to specify HTML attributes" do
      html = form_for("/books") do |f|
        f.datalist "book.store", values, "books", class: "form-control"
      end

      expect(html).to include %(<input type="text" name="book[store]" id="book-store" value="" class="form-control" list="books"><datalist id="books"><option value="Italy"></option><option value="United States"></option></datalist>)
    end

    it "allows to specify HTML attributes for options" do
      html = form_for("/books") do |f|
        f.datalist "book.store", values, "books", options: {class: "form-option"}
      end

      expect(html).to include %(<input type="text" name="book[store]" id="book-store" value="" list="books"><datalist id="books"><option value="Italy" class="form-option"></option><option value="United States" class="form-option"></option></datalist>)
    end

    it "allows to specify HTML attributes for datalist" do
      html = form_for("/books") do |f|
        f.datalist "book.store", values, "books", datalist: {class: "form-option"}
      end

      expect(html).to include %(<input type="text" name="book[store]" id="book-store" value="" list="books"><datalist class="form-option" id="books"><option value="Italy"></option><option value="United States"></option></datalist>)
    end

    context "with a Hash of values" do
      let(:values) { {"Italy" => "it", "United States" => "us"} }

      it "renders" do
        html = form_for("/books") do |f|
          f.datalist "book.store", values, "books"
        end

        expect(html).to include %(<input type="text" name="book[store]" id="book-store" value="" list="books"><datalist id="books"><option value="Italy">it</option><option value="United States">us</option></datalist>)
      end
    end
  end
end
