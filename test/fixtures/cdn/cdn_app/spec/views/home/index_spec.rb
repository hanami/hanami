require 'spec_helper'
require_relative '../../../app/views/home/index'

describe CdnApp::Views::Home::Index do
  let(:exposures) { Hash[foo: 'bar'] }
  let(:template)  { Hanami::View::Template.new('app/templates/home/index.html.erb') }
  let(:view)      { CdnApp::Views::Home::Index.new(template, exposures) }
  let(:rendered)  { view.render }

  it 'exposes #foo' do
    view.foo.must_equal exposures.fetch(:foo)
  end
end
