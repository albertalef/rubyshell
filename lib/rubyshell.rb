# frozen_string_literal: true

require_relative "rubyshell/version"
require_relative "rubyshell/command"
require_relative "rubyshell/chainer"
require_relative "rubyshell/chain_context"
require_relative "rubyshell/executor"
require_relative "rubyshell/error"

module Kernel
  def sh(&block)
    if block.nil?
      RubyShell::Executor
    else
      RubyShell::Executor.class_eval(&block)
    end
  end
end
