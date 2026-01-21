# frozen_string_literal: true

require "open3"
require "debug"

module RubyShell
  module TerminalExecutor
    SELECT_TIMEOUT = Rational(1, 20).freeze

    def self.capture(command, _options) # rubocop:disable Metrics/PerceivedComplexity,Metris/MethodLength,Metrics/CyclomaticComplexity,Metrix/AbcSize
      Open3.popen3(command) do |stdin, stdout, stderr, w_thread|
        stdin.close

        status = w_thread.join&.value

        output = (stdout.respond_to?(:ready?) ? stdout.ready?&.read : nil) || ""

        if status && !status.success?
          begin
            error = (stderr.respond_to?(:ready?) ? stderr.ready?&.read_nonblock(4098) : nil) || ""
          rescue EOFError
            error = ""
          ensure
            raise RubyShell::CommandError.new(
              command: command,
              stdout: output,
              stderr: error,
              status: status
            )
          end
        end

        RubyShell::Results::StringResult.new(output.chomp)
      rescue StandardError => e
        raise e if e.is_a?(RubyShell::CommandError)

        raise RubyShell::CommandError.new(command: command, message: e.message)
      end
    end
  end
end
