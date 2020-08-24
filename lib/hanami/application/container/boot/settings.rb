# frozen_string_literal: true

Hanami.application.register_bootable :settings do
  start do
    register :settings, Hanami.application.settings
  end
end
