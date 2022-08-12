# frozen_string_literal: true

require "hanami"
return if Hanami.app?

require "bundler/setup"
require "hanami/app_detector"

app_path = Hanami::AppDetector.new.()

if app_path
  require app_path
else
  raise <<~MSG unless app_path
    Hanami hasn't been able to locate your application file. It should be found in
    the `config/app.rb` file (or `app.rb` for single file applications).
  MSG
end
