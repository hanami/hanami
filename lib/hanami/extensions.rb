if Hanami.bundled?("hanami-controller")
  require_relative "extensions/action"
end

if Hanami.bundled?("hanami-view")
  require "hanami/view"
  require_relative "extensions/view"
  require_relative "extensions/view/context"
  require_relative "extensions/view/part"
  require_relative "extensions/view/scope"
end
