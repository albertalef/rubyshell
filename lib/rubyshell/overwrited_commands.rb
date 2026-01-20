# frozen_string_literal: true

module RubyShell
  module OverwritedCommands
    def self.included(mod)
      mod.extend self
    end

    def cd(path, &block)
      Dir.chdir(path, &block)
    end

    def ls(*args)
      method_missing(*args)
    end
  end
end
