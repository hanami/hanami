module Hanami
  module Version
    # @since 0.9.0
    # @api private
    VERSION = '0.9.0'.freeze

    # @since 0.9.0
    # @api private
    def self.version
      VERSION
    end

    # @since 0.9.0
    # @api private
    def self.gem_requirement
      if prerelease?
        version
      else
        "~> #{major_minor}"
      end
    end

    # @since 0.9.0
    # @api private
    def self.prerelease?
      version =~ /alpha|beta|rc/
    end

    # @since 0.9.0
    # @api private
    def major_minor
      version.scan(/\A\d{1,2}\.\d{1,2}/).first
    end
  end

  # Defines the full version
  #
  # @since 0.1.0
  VERSION = Version.version
end
