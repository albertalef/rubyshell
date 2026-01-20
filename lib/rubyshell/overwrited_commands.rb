# frozen_string_literal: true

module RubyShell
  module OverwritedCommands
    def self.included(mod)
      mod.extend self
    end

    def cd(path, &block)
      Dir.chdir(path, &block)
    end
  end
end
