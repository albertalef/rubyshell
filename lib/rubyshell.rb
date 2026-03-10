# frozen_string_literal: true

require "logger"

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
require_relative "rubyshell/debugger"
require_relative "rubyshell/env_proxy"
require_relative "rubyshell/parallel_executor"

module RubyShell
  class << self
    def debug=(value)
      @debug_mode = !!value
    end

    def debug(value = true) # rubocop:disable Style/OptionalBooleanParameter
      previous_value = @debug_mode

      @debug_mode = value.nil? ? @debug_mode : value

      result = yield

      @debug_mode = previous_value

      result
    end

    def debug?
      @debug_mode == true
    end

    attr_writer :logger

    def logger
      @logger ||= Logger.new($stdout)
    end

    def log_level=(level)
      @log_level = level.to_s
    end

    def log(text)
      logger.send(@log_level || :info, text)
    end

    def env
      RubyShell::EnvProxy
    end

    def config(kwargs)
      env.set(kwargs[:env]) if kwargs[:env]
    end
  end
end

module Kernel
  def sh(command = nil, *args, **kwargs, &block)
    if command
      RubyShell::Executor.send(command, *args, **kwargs)
    elsif block.nil?
      RubyShell::Executor
    else
      RubyShell.config(kwargs)

      RubyShell.debug(kwargs[:debug]) do
        RubyShell::Executor.class_eval(&block)
      end
    end
  end
end

class String
  def quoted
    "\"#{self}\""
  end
end
