# frozen_string_literal: true

module Hanami
  CONTAINER_KEY_DELIMITER = "."
  private_constant :CONTAINER_KEY_DELIMITER

  # @api private
  MODULE_DELIMITER = "::"
  private_constant :MODULE_DELIMITER

  PATH_DELIMITER = "/"
  private_constant :PATH_DELIMITER

  # @api private
  CONFIG_DIR = "config"
  private_constant :CONFIG_DIR

  # @api private
  SLICES_DIR = "slices"
  private_constant :SLICES_DIR

  # @api private
  LIB_DIR = "lib"
  private_constant :LIB_DIR

  # @api private
  RB_EXT = ".rb"
  private_constant :RB_EXT
end
