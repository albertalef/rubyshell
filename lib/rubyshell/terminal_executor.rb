# frozen_string_literal: true

require "open3"

module RubyShell
  module TerminalExecutor
    def self.capture(command, options) # rubocop:disable Metris/MethodLength,Metrics/CyclomaticComplexity,Metrix/AbcSize,Metrics/PerceivedComplexity
      stdin_value = if options[:_stdin].is_a?(RubyShell::Command) || options[:_stdin].is_a?(RubyShell::Chainer)
                      options[:_stdin].exec
                    else
                      options[:_stdin]
                    end

      env_hash = RubyShell.env.to_h.merge(options[:_env]&.transform_keys(&:to_s) || {})

      Open3.popen3(env_hash, command) do |stdin, stdout, stderr, w_thread|
        stdin.write(stdin_value) if stdin_value

        stdin.close

        stdout.binmode
        stderr.binmode

        output = +""
        error = +""
        ios = { stdout => output, stderr => error }

        # Block until a pipe has data (or hits EOF) instead of polling, so we
        # dont burn a CPU core spinning while the command runs.
        # EOF on both pipes empties ios and ends the loop, then we reap the exit status
        until ios.empty?
          readable, = IO.select(ios.keys)

          readable.each do |io|
            loop do
              chunk = io.read_nonblock(4096, exception: false)
              case chunk
              when :wait_readable
                break
              when nil
                ios.delete(io)
                break
              else
                ios[io] << chunk
              end
            end
          end
        end

        status = w_thread.value

        if status && !status.success?
          raise RubyShell::CommandError.new(
            command: command,
            stdout: output,
            stderr: error,
            status: status
          )
        end

        RubyShell::Results::StringResult.new(
          output.chomp,
          metadata: {
            command: command,
            exit_status: status
          }
        )
      end
    rescue StandardError => e
      raise e if e.is_a?(RubyShell::CommandError)

      raise RubyShell::CommandError.new(command: command, message: e.message)
    end
  end
end
