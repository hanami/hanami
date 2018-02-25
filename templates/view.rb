begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"

  gem "rake"
  gem "hanami-view", github: "hanami/view"
  gem "rspec"
  gem "rspec-core"
end

require 'hanami/view'

module Books
  class Index
    include Hanami::View

    def header
      'Hello from one file hanami app!'
    end
  end
end

Hanami::View.load!

require 'rspec'
require 'rspec/autorun'

RSpec.describe Books::Index do
  let(:template) do
    Tilt.register Tilt::ERBTemplate, 'rb'
    Hanami::View::Template.new(DATA.path)
  end

  let(:view) { Books::Index.new(template, **params) }
  let(:params) { Hash[] }

  it 'renders page' do
    expect(view.header).to eq 'Hello from one file hanami app!'
  end

  it 'renders page' do
    expect(view.render).to match 'Hello from one file hanami app!'
  end
end

__END__
<html>
  <head>
    <title>Super Simple Hanami App</title>
  </head>
  <body>
    <%= header %>
  </body>
</html>
