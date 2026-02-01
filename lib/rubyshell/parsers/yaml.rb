# frozen_string_literal: true

require "yaml"

module RubyShell
  module Parsers
    class Yaml < Base
      def self.parse(value)
        YAML.safe_load(value, permitted_classes: [Symbol])
      end
    end
  end
end
