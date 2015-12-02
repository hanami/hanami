# require 'lotus/model'
# require 'lotus/mailer'
# Dir["#{ __dir__ }/static_assets_app/**/*.rb"].each { |file| require_relative file }

# Lotus::Model.configure do
#   adapter type: :file_system, uri: ENV['STATIC_ASSETS_APP_DATABASE_URL']
#   mapping do
#   end
# end.load!

# Lotus::Mailer.configure do
#   root "#{ __dir__ }/static_assets_app/mailers"

#   delivery do
#     development :test
#     test        :test
#   end
# end.load!
