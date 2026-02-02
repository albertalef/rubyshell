# frozen_string_literal: true

module RubyShell
  class Parser
    class ParserNotFound < StandardError
    end

    def self.parse(parser_key, value)
      parser_class = locate_parser(parser_key)

      parser_class.parse(value)
    end

    def self.locate_parser(parser_key)
      Object.const_get("RubyShell::Parsers::#{parser_key.to_s.split("_").map(&:capitalize).join}")
    rescue NameError
      raise ParserNotFound
    end
  end
end
