# frozen_string_literal: true

module RubyShell
  module Debugger
    class << self
      def run_wrapper(command, debug: nil)
        if debug || RubyShell.debug?
          time_one = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          result = yield
          time_two = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          log_result(command, result, time_two - time_one)

          result
        else
          yield
        end
      end

      private

      def log_result(command, result, duration)
        meta = result.metadata
        text = +"\nExecuted: #{command.to_shell.chomp}\n"

        if meta[:remote]
          text << "  Host: #{meta[:host]}\n"
          text << "  Port: #{meta[:port]}\n"
        else
          text << "  Pid: #{meta[:exit_status].pid}\n"
        end

        text << "  Duration: #{format("%.6f", duration)}s\n"
        text << "  Exit code: #{meta[:exit_status].to_i}\n"
        text << "  Stdout: #{result.to_s.inspect}\n"

        RubyShell.log(text)
      end
    end
  end
end
