require 'spec_helper'
require_relative '../../../app/views/users/show'

describe RakeTasksApp::Views::Users::Show do
  let(:exposures) { Hash[foo: 'bar'] }
  let(:template)  { Hanami::View::Template.new('app/templates/users/show.html.erb') }
  let(:view)      { RakeTasksApp::Views::Users::Show.new(template, exposures) }
  let(:rendered)  { view.render }

  it 'exposes #foo' do
    view.foo.must_equal exposures.fetch(:foo)
  end
end
