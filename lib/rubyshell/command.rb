# frozen_string_literal: true

module RubyShell
  class Command
    attr_accessor :command_name, :options

    def initialize(command_name, *args, &block)
      @command_name = command_name
      @args = args
      @options = extract_options(args)
      @block = block
    end

    def to_shell
      [@command_name.to_s.gsub("!", ""), *parsed_args].join(" ")
    end

    def exec_command
      RubyShell::Debugger.run_wrapper(self, debug: @options[:_debug]) do
        result = RubyShell::TerminalExecutor.capture(to_shell, @options)

        result = RubyShell::Parser.parse(@options[:_parse], result) if @options[:_parse]

        result
      end
    end

    alias exec exec_command

    def parsed_args
      @args.map do |arg|
        case arg
        when Hash
          map_hash_arg(arg)
        else
          RubyShell::Sanitizer.sanitize_to_shell(arg.to_s)
        end
      end.flatten
    end

    private

    def method_missing(method_name, *args, &block)
      if method_name.start_with?(/[^A-Za-z0-9]/)
        RubyShell::Chainer.new(self).send(method_name, *args, block)
      else
        super
      end
    end

    def respond_to_missing?(_name, _include_private)
      false
    end

    def extract_options(args)
      args.reduce({}) do |acc, value|
        next acc unless value.is_a?(Hash)

        acc.merge(value)
      end
    end

    def map_hash_arg(arg)
      arg.map do |k, v|
        next if k.start_with?("_")

        if v.is_a?(Array)
          v.map do |e|
            map_hash_entry_to_string(k, e)
          end.join(" ")
        else
          map_hash_entry_to_string(k, v)
        end
      end.compact
    end

    def map_hash_entry_to_string(key, value)
      key_string = if key.length == 1
                     "-#{key}"
                   else
                     "--#{key}"
                   end

      [
        key_string,
        value.is_a?(TrueClass) ? nil : RubyShell::Sanitizer.sanitize_to_shell("'#{value}'")
      ].compact.join(" ")
    end
  end
end
