module RubyShell
  class Parser
    class ParserNotFound < StandardError
    end

    def self.parse(parser_key, value)
      parser_class = "RubyShell::Parsers::#{parser_key.classify}".safe_constantize

      raise ParserNotFound unless parser_class

      parser_class.parse(value)
    end
  end
end
