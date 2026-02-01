module RubyShell
  module Parsers
    class Base
      def self.parse(_value)
        raise NotImplementedError
      end
    end
  end
end
