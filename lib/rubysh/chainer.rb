
module Rubysh
  class Chainer
    def initialize(*commands)
      raise 'Cannot chain non commands' if commands.any? { |a| !a.is_a?(Rubysh::Command)}

      @commands = commands
    end

    def |(arg)
      raise 'Cannot chain non commands' if !arg.is_a?(Rubysh::Command)

      if arg.is_a?(Rubysh::Chainer)
        @commands += arg.commands
      else
        @commands << arg
      end

      self
    end

    def <<(arg)
      raise 'Cannot chain non commands' if !arg.is_a?(Rubysh::Command)

      if arg.is_a?(Rubysh::Chainer)
        @commands = [*arg.commands, *@commands]
      else
        @commands.unshift(arg)
      end

      self
    end

    def exec_commands
      %x{#{to_shell}}
    end

    def commands
      @commands
    end

    def command_strings
      @commands.map(&:to_shell)
    end

    def to_shell
      command_strings.join(' | ')
    end

    def inspect
      puts exec_commands
    end
  end
end
