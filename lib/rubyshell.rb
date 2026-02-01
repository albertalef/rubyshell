# frozen_string_literal: true

require_relative "rubyshell/version"
require_relative "rubyshell/command"
require_relative "rubyshell/chainer"
require_relative "rubyshell/chain_context"
require_relative "rubyshell/overwrited_commands"
require_relative "rubyshell/executor"
require_relative "rubyshell/error"
require_relative "rubyshell/results/string_result"
require_relative "rubyshell/terminal_executor"
require_relative "rubyshell/sanitizer"
require_relative "rubyshell/parser"
require_relative "rubyshell/parsers/base"

module Kernel
  def sh(command = nil, *args, &block)
    if command
      RubyShell::Executor.send(command, *args)
    elsif block.nil?
      RubyShell::Executor
    else
      RubyShell::Executor.class_eval(&block)
    end
  end
end

class String
  def quoted
    "\"#{self}\""
  end
end
