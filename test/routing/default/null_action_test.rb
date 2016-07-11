require 'test_helper'

describe Hanami::Routing::Default::NullAction do
  it 'is not renderable' do
    action = Hanami::Routing::Default::NullAction.new
    action.wont_be :renderable?
  end
end
