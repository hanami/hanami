# frozen_string_literal: true

if Hanami.bundled?("hanami-controller")
  require_relative "./extensions/action"
end

if Hanami.bundled?("hanami-view")
  require_relative "./extensions/view"
  require_relative "./extensions/view/context"
end
