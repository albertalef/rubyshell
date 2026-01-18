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
      else
        super
      end
    end

    def respond_to_missing?(_name, _include_private)
      false
    end

    def exec_commands
      Open3.capture3(to_shell).then do |stdout, stderr, status|
        unless status.success?
          raise RubyShell::CommandError.new(command: to_shell, stdout: stdout, stderr: stderr, status: status)
        end

        stdout.chomp
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
  end
end
