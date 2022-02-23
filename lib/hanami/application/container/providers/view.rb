# frozen_string_literal: true

Hanami.application.register_provider :view do
  prepare do
    require "hanami-view"
  rescue LoadError # rubocop:disable Lint/SuppressedException
  end

  start do
    if defined?(Hanami::View) && defined?(Hanami.application.namespace::View::Context)
      register "view.context", Hanami.application.namespace::View::Context.new
    end
  end
end
