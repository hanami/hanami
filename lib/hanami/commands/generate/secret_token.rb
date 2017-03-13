require 'hanami/commands/generate/abstract'
require 'hanami/application_name'
require 'securerandom'

module Hanami
  # @api private
  module Commands
    # @api private
    class Generate
      # @api private
      class SecretToken

        # @api private
        def initialize(application_name)
          @application_name = application_name
        end

        # @api private
        def start
          if Hanami::Utils::Blank.blank?(@application_name)
            puts SecureRandom.hex(32)
          else
            puts "Set the following environment variable to provide the secret token:"
            puts %(#{ upcase_app_name }_SESSIONS_SECRET="#{ SecureRandom.hex(32) }")
          end
        end

        private
        # @api private
        def upcase_app_name
          @application_name.upcase
        end

      end
    end
  end
end
