
module Rubysh
    class Executor
    def self.method_missing(method_name, *args, &)
      Rubysh::Command.new(method_name, *args, &)
    end

    def self.respond_to_missing?(name, _include_private)
      false
    end
  end

end
