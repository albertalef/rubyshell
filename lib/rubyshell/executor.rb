# frozen_string_literal: true

module RubyShell
  class Executor
    def self.cd(path, &block)
      Dir.chdir(path, &block)
    end

    def self.chain(&block)
      result = RubyShell::ChainContext.class_eval(&block).exec_commands

      raise "Command Failed" unless $?.success?

      result
    end

    def self.method_missing(method_name, *args)
      RubyShell::Command.new(method_name, *args).exec_command
    end

    def self.respond_to_missing?(_name, _include_private)
      false
    end
  end
end
