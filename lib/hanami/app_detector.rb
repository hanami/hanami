# frozen_string_literal: true

module Hanami
  # Detects the application file
  #
  # Locates the application file in the current directory or any of its parents.
  # It returns its absolute path when found, or `nil` otherwise.
  # 
  # @since 2.0.0
  # @api private
  class AppDetector
    VALID_APP_PATHS = %w[
      config/app
      app
    ].freeze
    private_constant :VALID_APP_PATHS

    # @param dir [String] The directory to start from.
    #   It defaults to the current directory.
    # @return [String, nil] The absolute path of the app file, or `nil`
    # @api private
    def call(dir: Dir.pwd)
      dir_path = Pathname.new(dir).expand_path

      detect_in(dir_path) ||
        (return if dir_path.root?) ||
        call(dir: dir_path.parent)
    end

    private

    def detect_in(dir_path)
      VALID_APP_PATHS.map do |app_path|
        File.join(dir_path, app_path) + ".rb"
      end.find { |f| File.exist?(f) && File.file?(f) }
    end
  end
end
