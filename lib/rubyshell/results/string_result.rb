# frozen_string_literal: true

module RubyShell
  module Results
    class StringResult < String
      def initialize(value, **kwargs)
        @_meta = kwargs.delete(:_meta)

        super(value)
      end

      attr_reader :_meta

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
