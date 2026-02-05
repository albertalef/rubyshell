# frozen_string_literal: true

module RubyShell
  class ChainContext
    def initialize(options = {})
      @options = options
    end

    def sh(command, *args)
      method_missing(command, *args)
    end

    def method_missing(method_name, *args, &block)
      RubyShell::Chainer.new(
        RubyShell::Command.new(method_name, *args, &block),
        @options
      )
    end

    def respond_to_missing?(_name, _include_private)
      false
    end
  end
end
