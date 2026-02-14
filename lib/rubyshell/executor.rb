# frozen_string_literal: true

module RubyShell
  module Executor
    module_function

    include RubyShell::OverwritedCommands

    def chain(options = {}, &block)
      RubyShell::ChainContext.new(options).instance_exec(&block).exec_commands
    end

    def parallel(options = {}, &block)
      RubyShell.debug(options[:debug]) do
        RubyShell::ParallelExecutor.new(options)._evaluate(&block)._run
      end
    end

    def remote(host, **options, &block)
      RubyShell::RemoteExecutor.new(host, **options).evaluate(&block)
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
