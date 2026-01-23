# frozen_string_literal: true

module RubyShell
  class ChainContext
    def self.sh(command, *args)
      method_missing(command, *args)
    end

    def self.method_missing(method_name, *args, &block)
      RubyShell::Chainer.new(RubyShell::Command.new(method_name, *(args << { _manual: true }), &block))
    end

    def self.respond_to_missing?(_name, _include_private)
      false
    end
  end
end
