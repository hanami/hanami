module Coverage
  def self.configure!
    return unless enabled?

    require 'simplecov'
    require 'coveralls'

    configure_simplecov!
  end

  def self.cover_as!(suite_name)
    return unless enabled?

    SimpleCov.command_name(suite_name)
  end

  private_class_method

  def self.ci?
    !ENV['TRAVIS'].nil?
  end

  def self.enabled?
    !ENV['COVERAGE'].nil?
  end

  def self.configure_simplecov!
    SimpleCov.formatter = Coveralls::SimpleCov::Formatter if ci?

    SimpleCov.start do
      add_filter 'test/'
      add_filter 'script/'
      add_filter 'tmp/'

      add_group 'Action',       'lib/hanami/action'
      add_group 'Commands',     'lib/hanami/commands'
      add_group 'Config',       'lib/hanami/config'
      add_group 'Generators',   'lib/hanami/generators'
      add_group 'Mailer',       'lib/hanami/mailer'
      add_group 'Repositories', 'lib/hanami/repositories'
      add_group 'Routing',      'lib/hanami/routing'
      add_group 'Templates',    'lib/hanami/templates'
      add_group 'Views',        'lib/hanami/views'
    end
  end
end
