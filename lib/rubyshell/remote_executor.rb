# frozen_string_literal: true

require_relative "ssh"

module RubyShell
  class RemoteExecutor
    RemoteCommand = Struct.new(:shell_string) do
      def to_shell
        shell_string
      end
    end

    RemoteStatus = Struct.new(:exit_code) do
      def to_i
        exit_code
      end

      def pid
        nil
      end

      def success?
        exit_code.zero?
      end
    end

    def initialize(host, port: 22, key: nil, timeout: SSH::DEFAULT_TIMEOUT, debug: nil)
      @host = host
      @port = port
      @key = key
      @timeout = timeout
      @debug = debug
    end

    def evaluate(&block)
      user, host = parse_host(@host)
      @connection = SSH.new(host, user: user, port: @port, key: @key, timeout: @timeout)

      instance_exec(&block)
    ensure
      @connection&.close
    end

    def sh(command, *args, **kwargs)
      method_missing(command, *args, **kwargs)
    end

    def chain(options = {}, &block)
      chainer = RubyShell::ChainContext.new(options).instance_exec(&block)
      execute_remote(chainer.to_shell)
    end

    def cd(path)
      execute_remote("cd '#{path.gsub("'", "'\\''")}'")
    end

    def method_missing(method_name, *args, **kwargs)
      command = RubyShell::Command.new(method_name.to_s.gsub(/!$/, ""), *args, **kwargs)

      execute_remote(command.to_shell)
    end

    def respond_to_missing?(_name, _include_private)
      false
    end

    private

    def parse_host(host_string)
      if host_string.include?("@")
        host_string.split("@", 2)
      else
        [ENV.fetch("USER", nil), host_string]
      end
    end

    def execute_remote(shell_string)
      wrapper = RemoteCommand.new(shell_string)

      RubyShell::Debugger.run_wrapper(wrapper, debug: @debug) do
        result = @connection.execute(shell_string)

        unless result.success?
          raise RubyShell::CommandError.new(
            command: shell_string,
            stdout: result.stdout,
            stderr: result.stderr,
            status: result.exit_code
          )
        end

        status = RemoteStatus.new(result.exit_code)

        RubyShell::Results::StringResult.new(
          result.stdout,
          metadata: {
            command: shell_string,
            exit_status: status,
            remote: true,
            host: @host,
            port: @port
          }
        )
      end
    end
  end
end
