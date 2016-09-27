module Hanami
  module Version
    # @since x.x.x
    # @api private
    VERSION = '1.0.0.alpha1'.freeze

    # @since x.x.x
    # @api private
    def self.version
      VERSION
    end

    # @since x.x.x
    # @api private
    def self.gem_requirement
      if prerelease?
        version
      else
        "~> #{major_minor}"
      end
    end

    # @since x.x.x
    # @api private
    def self.prerelease?
      version =~ /alpha|beta|rc/
    end

    # @since x.x.x
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
