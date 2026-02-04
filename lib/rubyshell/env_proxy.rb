# frozen_string_literal: true

module RubyShell
  module EnvProxy
    class << self
      def env
        @env ||= {}
      end

      def to_h
        env
      end

      def []=(key, value)
        env[key.to_s] = value
      end

      def [](key)
        env[key.to_s]
      end

      def set(hash)
        @env = hash&.transform_keys(&:to_s) || {}
      end
    end
  end
end
