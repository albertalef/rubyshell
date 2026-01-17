# frozen_string_literal: true

require "open3"

module RubyShell
  class Chainer
    attr_reader :parts

    def initialize(command)
      @parts = [command]
    end

    def handle_chain(operator, chainer)
      @parts = [
        *@parts,
        operator.to_s,
        *(chainer.is_a?(RubyShell::Chainer) ? chainer.parts : chainer)
      ]

      self
    end

    def method_missing(method_name, *args, &block)
      if method_name.start_with?(/[^A-Za-z0-9]/)
        handle_chain(method_name, args.first)

      elsif String.instance_methods.include?(method_name)
        exec_commands.send(method_name, *args, &block)

      else
        super
      end
    end

    def respond_to_missing?(_name, _include_private)
      false
    end

    def exec_commands
      Open3.capture3(to_shell).then do |stdout, stderr, status|
        if status.success?
          stdout.chomp
        else
          raise RubyShell::Command::Error.new(command: to_shell, stdout:, stderr:, status:)
        end
      end
    end

    def to_shell
      parts.map do |part|
        if part.is_a?(RubyShell::Command)
          part.to_shell
        else
          part
        end
      end.join(" ")
    end

    def to_s = exec_commands
    def to_str = to_s
    def inspect = to_s
  end
end
