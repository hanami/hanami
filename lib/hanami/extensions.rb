# frozen_string_literal: true

require_relative "./extensions/action" if Hanami.bundled?("hanami-controller")

if Hanami.bundled?("hanami-view")
  require_relative "./extensions/view"
  require_relative "./extensions/view/context"
end
