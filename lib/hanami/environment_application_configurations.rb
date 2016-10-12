module Hanami
  class EnvironmentApplicationConfigurations
    ALL = :all

    def initialize
      @configurations = Concurrent::Hash.new { |k, v| k[v] = [] }
    end

    def add(environment, &blk)
      env = (environment || ALL).to_sym
      configurations[env].push(blk)
    end

    def each(environment, &blk)
      configurations.each do |env, blks|
        next unless matching_env?(environment, env)
        blks.each(&blk)
      end
    end

    private

    attr_reader :configurations

    def matching_env?(environment, env)
      environment.to_sym == env ||
        env == ALL
    end
  end
end
