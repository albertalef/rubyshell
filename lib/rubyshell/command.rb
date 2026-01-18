# frozen_string_literal: true

require "open3"

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

    def exec_command
      Open3.capture3(to_shell).then do |stdout, stderr, status|
        unless status.success?
          raise RubyShell::CommandError.new(command: to_shell, stdout: stdout, stderr: stderr, status: status)
        end

        StringWrapper.new(stdout.chomp)
      end
    rescue StandardError => e
      raise e if e.is_a?(RubyShell::CommandError)

      raise RubyShell::CommandError.new(command: to_shell, message: e.message)
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
  end

  class StringWrapper < String
    def inspect
      if $stdin.isatty
        to_s
      else
        super
      end
    end
  end
end
