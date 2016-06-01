module Coverage
  module_function def configure!
    return unless enabled?

    require 'simplecov'
    require 'coveralls'

    configure_simplecov!
  end

  module_function def cover_as!(suite_name)
    return unless enabled?

    SimpleCov.command_name(suite_name)
  end

  private

  module_function def travis?
    !!ENV['TRAVIS']
  end

  module_function def enabled?
    !!ENV['COVERAGE']
  end


  module_function def configure_simplecov!
    if travis?
      SimpleCov.formatter = Coveralls::SimpleCov::Formatter
    end

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
