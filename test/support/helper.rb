require 'rubygems'
require 'bundler/setup'

# Autoloading 'tilt/erb' in a non thread-safe way
require 'tilt/erb'

FIXTURES_ROOT = Pathname(File.dirname(__FILE__) + '/../fixtures').realpath
ENV_LOCALHOST = !!ENV['TRAVIS'] ? '0.0.0.0' : 'localhost'

require 'minitest/autorun'
require 'support/assertions'

$:.unshift 'lib'
require 'hanami'

$pwd = Dir.pwd
