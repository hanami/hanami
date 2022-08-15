# frozen_string_literal: true

module Hanami
  # Locates and returns the app file (`config/app.rb`) from the current directory or any of its
  # parents. It returns its absolute path when found, or `nil` otherwise.
  #
  # @since 2.0.0
  # @api private
  class DetectApp
    # Expected path for the app file
    APP_PATH = "config/app.rb"
    private_constant :APP_PATH

    class << self
      # @param dir [String] The directory to start from. Defaults to the current directory.
      #
      # @return [String, nil] The absolute path of the app file, or `nil` if not found.
      def call(dir = Dir.pwd)
        dir = Pathname(dir).expand_path

        detect_in(dir) || (return if dir.root?) || call(dir.parent)
      end

      private

      def detect_in(dir)
        app_path = dir.join(APP_PATH)
        return app_path.to_s if app_path.file?
      end
    end
  end
end
