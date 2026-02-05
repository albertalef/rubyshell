# frozen_string_literal: true

require "debug"
module RubyShell
  class Chainer
    attr_reader :parts, :options

    def initialize(command, options = {})
      @parts = [command]
      @options = options
    end

    def handle_chain(operator, chainer)
      @parts = [
        *@parts,
        operator.to_s,
        *(chainer.is_a?(RubyShell::Chainer) ? chainer.parts : chainer)
      ]

      self
    end

    def settings
      @options.select { _1.to_s.start_with?("_") }
    end

    def method_missing(method_name, *args, &block)
      if method_name.start_with?(/[^A-Za-z0-9]/)
        handle_chain(method_name, args.first)
      else
        super
      end
    end

    def respond_to_missing?(_name, _include_private)
      false
    end

    def exec_commands
      result = RubyShell::Debugger.run_wrapper(self, debug: @options[:_debug]) do
        RubyShell::TerminalExecutor.capture(to_shell, settings)
      end

      result = RubyShell::Parser.parse(@options[:_parse], result) if @options[:_parse]

      result
    end

    alias exec exec_commands

    def to_shell
      parts.map do |part|
        if part.is_a?(RubyShell::Command)
          part.to_shell
        else
          part
        end
      end.join(" ")
    end
  end
end
