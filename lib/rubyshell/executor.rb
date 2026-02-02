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
#
# # Enable for single block
# sh(debug: true) do
#   mkdir("test")
#   cd("test") do
#     touch("file.txt")
#   end
# end
# # Output:
# # [DEBUG] Executing: mkdir test
# # [DEBUG]   Duration: 3ms
# # [DEBUG]   Exit code: 0
# # [DEBUG] Changing directory to: test
# # [DEBUG] Executing: touch file.txt
# # [DEBUG]   Duration: 2ms
# # [DEBUG]   Exit code: 0
#
# # Enable globally
# RubyShell.debug = true
#
# # Custom logger
# RubyShell.logger = Logger.new("rubyshell.log")
#
# # Log levels
# RubyShell.log_level = :info  # :debug, :info, :warn, :error
