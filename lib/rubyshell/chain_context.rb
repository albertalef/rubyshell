
module RubyShell
  class ChainContext
    def self.method_missing(method_name, *args, &)
      RubyShell::Chainer.new(RubyShell::Command.new(method_name, *(args << {_manual: true}), &))
    end

    def self.respond_to_missing?(name, _include_private)
      false
    end
  end
end
