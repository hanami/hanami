require 'hanami/router'
require 'hanami/view'
require 'hanami/controller'
require 'hanami/action/glue'
require 'hanami/action/csrf_protection'
require 'hanami/mailer'
require 'hanami/mailer/glue'
require 'hanami/assets'

Hanami::Controller.configure do
  prepare do
    include Hanami::Action::Glue
  end
end
