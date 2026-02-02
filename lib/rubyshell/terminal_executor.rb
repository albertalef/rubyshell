# frozen_string_literal: true

require "open3"

module RubyShell
  module TerminalExecutor
    SELECT_TIMEOUT = Rational(1, 20).freeze

    def self.capture(command, options) # rubocop:disable Metris/MethodLength,Metrics/CyclomaticComplexity,Metrix/AbcSize,Metrics/PerceivedComplexity
      stdin_value = if options[:_stdin].is_a?(RubyShell::Command) || options[:_stdin].is_a?(RubyShell::Chainer)
                      options[:_stdin].exec
                    else
                      options[:_stdin]
                    end

      Open3.popen3(command) do |stdin, stdout, stderr, w_thread|
        stdin.write(stdin_value) if stdin_value

        stdin.close

        stdout.binmode
        stderr.binmode

        output = +""
        error = +""
        ios = { stdout => output, stderr => error }

        status = nil

        # What was my idea here:
        # If has not any io readable and the program exited in the previous loop, stop
        until ios.empty?
          status ||= w_thread.join(0)

          readable, = IO.select(ios.keys, nil, nil, 0)

          break if !readable && status
          next unless readable

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

        RubyShell::Results::StringResult.new(output.chomp, _meta: {
                                               command: command,
                                               exit_status: status
                                             })
      end
    rescue StandardError => e
      raise e if e.is_a?(RubyShell::CommandError)

      raise RubyShell::CommandError.new(command: command, message: e.message)
    end
  end
end
