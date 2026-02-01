require "json"

module RubyShell
  module Parsers
    class Json < Base
      def self.parse(value)
        JSON.parse(value, symbolize_names: true)
      end
    end
  end
end
