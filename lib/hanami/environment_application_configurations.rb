module Hanami
  # @api private
  class EnvironmentApplicationConfigurations
    # @api private
    ALL = :all

    # @api private
    def initialize
      @configurations = Concurrent::Hash.new { |k, v| k[v] = [] }
    end

    # @api private
    def add(environment, &blk)
      env = (environment || ALL).to_sym
      configurations[env].push(blk)
    end

    # @api private
    def each(environment, &blk)
      configurations.each do |env, blks|
        next unless matching_env?(environment, env)
        blks.each(&blk)
      end
    end

    private

    # @api private
    attr_reader :configurations

    # @api private
    def matching_env?(environment, env)
      environment.to_sym == env ||
        env == ALL
    end
  end
end
