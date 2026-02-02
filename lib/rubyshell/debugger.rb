# frozen_string_literal: true

module RubyShell
  module Debugger
    class << self
      def run_wrapper(command, debug: nil)
        if debug || RubyShell.debug?

          time_one = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          result = yield

          time_two = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          RubyShell.log("Executed: #{command.to_shell.chomp}")
          RubyShell.log("  Duration: #{format("%.6f", time_two - time_one)}s")
          RubyShell.log("  Pid: #{result.metadata[:exit_status].pid}")
          RubyShell.log("  Exit code: #{result.metadata[:exit_status].to_i}")
          RubyShell.log("  Stdout: #{result.to_s.inspect}")

          result
        else
          yield
        end
      end
    end
  end
end
