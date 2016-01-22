require 'spec_helper'
require_relative '../../../../apps/web/views/users/show'

describe Web::Views::Users::Show do
  let(:exposures) { Hash[foo: 'bar'] }
  let(:template)  { Hanami::View::Template.new('apps/web/templates/users/show.html.erb') }
  let(:view)      { Web::Views::Users::Show.new(template, exposures) }
  let(:rendered)  { view.render }

  it 'exposes #foo' do
    view.foo.must_equal exposures.fetch(:foo)
  end
end
