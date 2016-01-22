# require 'hanami/model'
# require 'hanami/mailer'
# Dir["#{ __dir__ }/static_assets/**/*.rb"].each { |file| require_relative file }

# Hanami::Model.configure do
#   adapter type: :file_system, uri: ENV['STATIC_ASSETS_DATABASE_URL']
#   mapping do
#   end
# end.load!

# Hanami::Mailer.configure do
#   root "#{ __dir__ }/static_assets/mailers"

#   delivery do
#     development :test
#     test        :test
#   end
# end.load!
