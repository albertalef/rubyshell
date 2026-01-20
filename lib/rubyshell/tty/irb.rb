# frozen_string_literal: true

require "debug"

module RubyShell
  module Tty
    module IrbWorkspace
      def initialize(*args, **kwargs)
        super

        main.define_singleton_method(:to_s) do
          Dir.pwd.split("/").last(2).join("/")
        end

        @main.extend(RubyShell::Executor)
      end
    end
  end
end

IRB::WorkSpace.prepend(RubyShell::Tty::IrbWorkspace)

IRB.conf[:IRB_RC] = proc do |ctx|
  if defined?(IRB::Command) && IRB::Command.respond_to?(:commands)
    IRB::Command.commands.delete(:cd)
  elsif defined?(IRB::ExtendCommand) && IRB::ExtendCommand.respond_to?(:commands)
    IRB::ExtendCommand.commands.delete(:cd)
  end

  ctx.command_aliases.delete(:cd) if ctx.respond_to?(:command_aliases) && ctx.command_aliases
end
