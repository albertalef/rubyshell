
module Rubysh
  class Command
    def initialize(command_name, *args, &block)
      @command_name = command_name
      @args = args
      @block = block
    end

    def to_shell
      [@command_name.to_s.gsub("!", ''), *parsed_args].join(' ')
    end

    def exec_command
      %x{#{to_shell}}
    end

    def inspect
      puts exec_command
    end

    def parsed_args
      @args.map do |arg|
        case arg
        when Hash
          arg.map do |k, v|
            key = if k.length == 1
              "-#{k}"
            else
              "--#{k}"
            end

            [key, v.is_a?(TrueClass) ? nil : v].compact.join(" ")
          end
        else
          arg.to_s
        end
      end.flatten
    end

    def method_missing(method_name, *args, **hash_args, &)
      exec_command.send(method_name, *args, **hash_args, &)
    end

    def |(command)
      Rubysh::Chainer.new(self, command)
    end

    def <<(command)
      Rubysh::Chainer.new(command, self)
    end
  end
end
