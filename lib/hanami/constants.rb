# frozen_string_literal: true

module Hanami
  # @api private
  CONTAINER_KEY_DELIMITER = "."
  private_constant :CONTAINER_KEY_DELIMITER

  # @api private
  MODULE_DELIMITER = "::"
  private_constant :MODULE_DELIMITER

  # @api private
  PATH_DELIMITER = "/"
  private_constant :PATH_DELIMITER

  # @api private
  APP_PATH = "config/app.rb"
  private_constant :APP_PATH

  # @api private
  CONFIG_DIR = "config"
  private_constant :CONFIG_DIR

  # @api private
  APP_DIR = "app"
  private_constant :APP_DIR

  # @api private
  LIB_DIR = "lib"
  private_constant :LIB_DIR

  # @api private
  SLICES_DIR = "slices"
  private_constant :SLICES_DIR

  # @api private
  ROUTES_PATH = File.join(CONFIG_DIR, "routes")
  private_constant :ROUTES_PATH

  # @api private
  ROUTES_CLASS_NAME = "Routes"
  private_constant :ROUTES_CLASS_NAME

  # @api private
  SETTINGS_PATH = File.join(CONFIG_DIR, "settings")
  private_constant :SETTINGS_PATH

  # @api private
  SETTINGS_CLASS_NAME = "Settings"
  private_constant :SETTINGS_CLASS_NAME

  # @api private
  RB_EXT = ".rb"
  private_constant :RB_EXT
end
