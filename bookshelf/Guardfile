# frozen_string_literal: true

group :server do
  guard "puma", port: ENV.fetch("HANAMI_PORT", 2300) do
    # Edit the following regular expression for your needs.
    # See: https://guides.hanamirb.org/app/code-reloading/
    watch(%r{^(app|config|lib|slices)([\/][^\/]+)*.(rb|erb|haml|slim)$}i)
  end
end
