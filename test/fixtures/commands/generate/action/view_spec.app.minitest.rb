require 'spec_helper'
require_relative '../../../app/views/books/index'

describe Testapp::Views::Books::Index do
  let(:exposures) { Hash[foo: 'bar'] }
  let(:template)  { Lotus::View::Template.new('app/templates/books/index.html.erb') }
  let(:view)      { Testapp::Views::Books::Index.new(template, exposures) }
  let(:rendered)  { view.render }

  it 'exposes #foo' do
    view.foo.must_equal exposures.fetch(:foo)
  end
end
