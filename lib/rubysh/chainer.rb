
module Rubysh
  class Chainer
    def initialize(command)
      @parts = [command]
    end

    def handle_chain(operator, chainer)
      @parts = [*@parts, operator.to_s, *chainer.parts]

      self
    end

    def method_missing(method_name, *args, &)
      if method_name.start_with?(/[^A-Za-z0-9]/)
        handle_chain(method_name, args.first)
      else
        super
      end
    end

    def respond_to_missing?(name, _include_private)
      false
    end

    def exec_commands
      %x{#{to_shell}}.chomp
    end

    def parts
      @parts
    end

    def to_shell
      parts.map do |part|
        if part.is_a?(Rubysh::Command)
          part.to_shell
        else
          part
        end
      end.join(" ")
    end
  end
end
