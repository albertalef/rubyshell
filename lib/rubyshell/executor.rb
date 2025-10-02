# frozen_string_literal: true

module RubyShell
  class Executor
    def self.method_missing(method_name, *args)
      RubyShell::Command.new(method_name, *args).exec_command
    end

    def self.respond_to_missing?(_name, _include_private)
      false
    end
  end
end
