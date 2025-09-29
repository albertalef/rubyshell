# frozen_string_literal: true

require_relative "rubysh/version"

module Rubysh
  require_relative "rubysh/command"
  require_relative "rubysh/chainer"
  require_relative "rubysh/executor"
end

module Kernel
  def sh
    Rubysh::Executor
  end

  def sh_unsafe_mode(value)
    @sh_unsafe_mode = value
  end

  def method_missing(method_name, *args, &)
    if @sh_unsafe_mode
      Rubysh::Executor.send(method_name.to_s.gsub('!', ''), *args, &)
    else
      super
    end
  end
end
