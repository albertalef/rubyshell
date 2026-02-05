# frozen_string_literal: true

module RubyShell
  module Debugger
    class << self
      def run_wrapper(command, debug: nil)
        if debug || RubyShell.debug?

          time_one = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          result = yield

          time_two = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          RubyShell.log(<<~TEXT
            \nExecuted: #{command.to_shell.chomp}
              Duration: #{format("%.6f", time_two - time_one)}s
              Pid: #{result.metadata[:exit_status].pid}
              Exit code: #{result.metadata[:exit_status].to_i}
              Stdout: #{result.to_s.inspect}
          TEXT
                       )

          result
        else
          yield
        end
      end
    end
  end
end
