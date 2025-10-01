# frozen_string_literal: true

require_relative "rubyshell/version"
require_relative "rubyshell/command"
require_relative "rubyshell/chainer"
require_relative "rubyshell/chain_context"
require_relative "rubyshell/executor"

module Kernel
  def sh(&block)
    if !block.nil?
      RubyShell::Executor.class_eval(&block)
    else
      RubyShell::Executor
    end
  end

  def sh_unsafe_mode(value)
    @sh_unsafe_mode = value
  end

  def cd(path, &)
    Dir.chdir(path, &)
  end

  def method_missing(method_name, *args, &)
    if @sh_unsafe_mode
      RubyShell::Executor.send(method_name.to_s.gsub('!', ''), *args, &)
    else
      super
    end
  end

  def chain(&)
    RubyShell::ChainContext.class_eval(&).exec_commands
  end
end
