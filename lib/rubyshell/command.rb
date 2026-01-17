# frozen_string_literal: true

module RubyShell
  class Command
    def initialize(command_name, *args, &block)
      @command_name = command_name
      @args = args
      @block = block
    end

    def to_shell
      [@command_name.to_s.gsub("!", ""), *parsed_args].join(" ")
    end

    def parsed_args
      @args.map do |arg|
        case arg
        when Hash
          map_hash_arg(arg)
        else
          arg.to_s
        end
      end.flatten
    end

    private

    def map_hash_arg(arg)
      arg.map do |k, v|
        next if k.start_with?("_")

        key = if k.length == 1
                "-#{k}"
              else
                "--#{k}"
              end

        [key, v.is_a?(TrueClass) ? nil : "'#{v}'"].compact.join(" ")
      end.compact
    end

    class Error < StandardError
      attr_reader :stdout, :stderr, :status, :command

      def initialize(command:, stdout:, stderr:, status:)
        @command = command
        @stdout = stdout
        @stderr = stderr
        @status = status
        super("Command failed: #{command}\n#{stderr.chomp}")
      end

      def exit_code = status.exitstatus
    end
  end
end
