# frozen_string_literal: true

module RubyShell
  module Executor
    module_function

    def cd(path, &block)
      Dir.chdir(path, &block)
    end

    def chain(&block)
      RubyShell::ChainContext.class_eval(&block).exec_commands
    end

    def method_missing(method_name, *args)
      RubyShell::Command.new(method_name, *args).exec_command
    end

    def respond_to_missing?(_name, _include_private)
      false
    end
  end
end
