require 'pathname'

module Lotus
  class Configuration
    def initialize(&blk)
      instance_eval(&blk)
    end

    def routes(&blk)
      if block_given?
        @routes = blk
      else
        @routes
      end
    end

    def root(value = nil)
      if value
        @root = Pathname.new(value).realpath
      else
        @root
      end
    end

    def controller_suffix(value = nil)
      if value
        @controller_suffix = value
      else
        @controller_suffix ||= 'Controller'
      end
    end

    def controller_namespace(value = nil)
      if value
        @controller_namespace = value
      else
        @controller_namespace ||= "(::#{ controller_suffix }::|#{ controller_suffix }::)"
      end
    end

    def view_namespace(value = nil)
      if value
        @view_namespace = value
      else
        @view_namespace ||= 'Views::'
      end
    end

    def view_suffix(value = nil)
      if value
        @view_suffix = value
      else
        @view_suffix ||= 'View'
      end
    end

    def template_prefix(value = nil)
      if value
        @template_prefix = value
      else
        @template_prefix ||= 'views'
      end
    end

    def template_suffix(value = nil)
      if value
        @template_suffix = value
      else
        @template_suffix ||= 'templates'
      end
    end
  end
end
