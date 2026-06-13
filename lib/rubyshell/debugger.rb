# frozen_string_literal: true

module RubyShell
  module Debugger
    class << self
      def run_wrapper(command, debug: nil)
        if debug || RubyShell.debug?
          time_one = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          begin
            result = yield
          rescue RubyShell::CommandError => e
            time_two = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            log_command(command, time_two - time_one, e.status, e.stdout, e.stderr)
            raise
          end

          time_two = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          log_command(command, time_two - time_one, result.metadata[:exit_status], result.to_s, "")

          result
        else
          yield
        end
      end

      private

      def log_command(command, duration, status, stdout, stderr)
        RubyShell.log(<<~TEXT
          \nExecuted: #{command.to_shell.chomp}
            Duration: #{format("%.6f", duration)}s
            Pid: #{status.respond_to?(:pid) ? status.pid : ""}
            Exit code: #{status.respond_to?(:exitstatus) ? status.exitstatus : status.to_i}
            Stdout: #{stdout.inspect}
            Stderr: #{stderr.inspect}
        TEXT
                     )
      end
    end
  end
end
