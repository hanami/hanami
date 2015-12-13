require 'lotus'
require 'lotus/model'
require 'lotus/helpers'
require 'securerandom'

ADAPTER_TYPE = if Lotus::Utils.jruby?
                 require 'jdbc/sqlite3'
                 Jdbc::SQLite3.load_driver

                 'jdbc:sqlite'
               else
                 require 'sqlite3'

                 'sqlite'
               end

require 'lotus/model/adapters/sql_adapter'

db = Pathname.new(File.dirname(__FILE__)).join('../tmp/test.sqlite3')
db.dirname.mkpath      # create directory if not exist
db.delete if db.exist? # delete file if exist

SQLITE_CONNECTION_STRING = "#{ ADAPTER_TYPE }://#{ db }"

DB = Sequel.connect(SQLITE_CONNECTION_STRING)

DB.create_table :books do
  primary_key :id
  String :name
end

module Collaboration
  class Application < Lotus::Application
    configure do
      layout :application
      load_paths << 'app'
      routes 'config/routes'

      sessions :cookie, secret: SecureRandom.hex

      assets do
        digest true # FIXME remove when global assets static handler will be implemented
        sources << [
          'vendor/assets',
          '../../vendor/assets'
        ]
      end

      adapter type: :sql, uri: SQLITE_CONNECTION_STRING
      mapping 'config/mapping'

      # SIMULATE DISABLED SECURITY HEADERS
      #
      # security.x_frame_options         "DENY"
      # security.content_security_policy "connect-src 'self'"

      view.prepare do
        include Lotus::Helpers
        include Lotus::Helpers::AssetTagHelpers
      end

      controller.prepare do
        # Always run CSRF Protection when running full stack integration specs, even when LOTUS_ENV is set to
        # test (it may happen depending on the order of specs and the way minitest works)
        before :set_csrf_token, :verify_csrf_token

        include Module.new {

          private
          def generate_csrf_token
            't0k3n'
          end
        }
      end
    end
  end
end
