require 'ostruct'
require_relative './config_loader'

module Kernel
  def load_config(path, overrides = [])
    ConfigLoader.new(File.open(path), overrides).config
  end
end
