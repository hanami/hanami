# frozen_string_literal: true

require "dry/system"
require "pathname"

# FIXME: dry-system wants this to be a Pathname but it really shoudn't need to be
Dry::System.register_provider :hanami, boot_path: Pathname(File.join(__dir__, "components"))
