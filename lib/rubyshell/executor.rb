# frozen_string_literal: true

module RubyShell
  module Executor
    module_function

    include RubyShell::OverwritedCommands

    def chain(&block)
      RubyShell::ChainContext.class_eval(&block).exec_commands
    end

    def method_missing(method_name, *args, **kwargs)
      command = RubyShell::Command.new(method_name.to_s.gsub(/!$/, ""), *args, **kwargs)

      if method_name.to_s.match?(/!$/)
        command
      else
        command.exec_command
      end
    end

    def respond_to_missing?(_name, _include_private)
      false
    end
  end
end
