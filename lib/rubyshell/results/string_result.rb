# frozen_string_literal: true

module RubyShell
  module Results
    class StringResult < String
      def inspect
        if $stdin.isatty
          to_s
        else
          super
        end
      end
    end
  end
end
