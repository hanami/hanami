require 'spec_helper'
require_relative '../../../app/views/home/dashboard'

describe StaticAssetsApp::Views::Home::Dashboard do
  let(:exposures) { Hash[foo: 'bar'] }
  let(:template)  { Hanami::View::Template.new('app/templates/home/dashboard.html.erb') }
  let(:view)      { StaticAssetsApp::Views::Home::Dashboard.new(template, exposures) }
  let(:rendered)  { view.render }

  it 'exposes #foo' do
    view.foo.must_equal exposures.fetch(:foo)
  end
end
