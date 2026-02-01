require "json"

module RubyShell
  module Parsers
    class Json < Base
      def self.parse(value)
        JSON.parse(value)
      end
    end
  end
end
