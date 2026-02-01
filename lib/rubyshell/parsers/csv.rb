# frozen_string_literal: true

require "csv"

module RubyShell
  module Parsers
    class Csv < Base
      def self.parse(value)
        CSV.parse(value)
      end
    end
  end
end
