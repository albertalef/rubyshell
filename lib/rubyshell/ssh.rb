# frozen_string_literal: true

require "open3"
require "securerandom"
require "timeout"

module RubyShell
  class SSH
    class CommandTimeout < StandardError; end

    Result = Struct.new(:stdout, :stderr, :exit_code) do
      alias_method :to_s, :stdout
      alias_method :output, :stdout

      def success?
        exit_code.zero?
      end

      def lines
        stdout.lines
      end
    end

    attr_reader :host, :port, :user

    DEFAULT_TIMEOUT = 30

    def initialize(host, user:, port: 22, key: nil, timeout: DEFAULT_TIMEOUT)
      @host = host
      @user = user
      @port = port
      @timeout = timeout

      cmd = [
        "ssh",
        "-o", "StrictHostKeyChecking=no",
        "-p", port.to_s,
        "-T"
      ]

      cmd += ["-i", key] if key

      cmd << "#{user}@#{host}"

      @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(*cmd)
    end

    def execute(command, timeout: @timeout) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      delim = "__RUBYSHELL_#{SecureRandom.hex(8)}__"

      @stdin.puts("#{command}; echo \"#{delim} $?\"; echo #{delim} >&2")
      @stdin.flush

      stdout_buf = +""
      stderr_buf = +""
      exit_code = 0
      stdout_done = false
      stderr_done = false
      ios = [@stdout, @stderr]

      Timeout.timeout(timeout, CommandTimeout, "command timed out after #{timeout}s: #{command}") do
        until stdout_done && stderr_done
          break if ios.empty?

          readable, = IO.select(ios, nil, nil, 0.1)
          next unless readable

          readable.each do |io|
            chunk = io.read_nonblock(4096, exception: false)

            if chunk.nil?
              ios.delete(io)
              stdout_done = true if io == @stdout
              stderr_done = true if io == @stderr
              next
            end

            next if chunk == :wait_readable

            if io == @stdout
              stdout_buf << chunk
              if stdout_buf.include?(delim)
                before, delim_line = stdout_buf.split(delim, 2)
                stdout_buf = before
                exit_code = delim_line.strip.to_i
                stdout_done = true
              end
            else
              stderr_buf << chunk
              if stderr_buf.include?(delim)
                stderr_buf = stderr_buf.split(delim, 2).first
                stderr_done = true
              end
            end
          end
        end
      end

      Result.new(stdout_buf.chomp, stderr_buf.chomp, exit_code)
    end

    def close
      [@stdin, @stdout, @stderr].each { |io| io&.close rescue nil } # rubocop:disable Style/RescueModifier
      @wait_thread&.join(5)
    end
  end
end
